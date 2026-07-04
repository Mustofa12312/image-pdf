use anyhow::{Context, Result};
use pdfium_render::prelude::*;
use serde::{Deserialize, Serialize};
use std::path::Path;
use std::process::Command;

#[derive(Serialize, Deserialize)]
pub struct PageInfo {
    pub page_number: usize,
    pub width: i32,
    pub height: i32,
}

#[derive(Serialize)]
pub struct ConversionResult {
    #[serde(rename = "type")]
    pub result_type: String,
    pub success: bool,
    pub total_items: usize,
    pub output_files: Vec<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error_code: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error_message: Option<String>,
}

#[derive(Serialize)]
struct ProgressMsg {
    #[serde(rename = "type")]
    msg_type: String,
    current: usize,
    total: usize,
}

#[derive(Serialize)]
struct OutputMsg {
    #[serde(rename = "type")]
    msg_type: String,
    file: String,
}

/// Get page count and dimensions using PDFium (no rendering, just metadata).
pub fn get_pdf_info(input_path: &str) -> Result<Vec<PageInfo>> {
    let pdfium = Pdfium::default();
    let doc = pdfium
        .load_pdf_from_file(input_path, None)
        .with_context(|| format!("Failed to open PDF: {}", input_path))?;

    let pages: Vec<PageInfo> = doc
        .pages()
        .iter()
        .enumerate()
        .map(|(i, page)| {
            let size = page.page_size();
            PageInfo {
                page_number: i + 1,
                width: size.width().value as i32,
                height: size.height().value as i32,
            }
        })
        .collect();

    Ok(pages)
}

/// Convert PDF pages to images using pdftoppm (poppler-utils).
/// This produces pixel-perfect, color-accurate results — the same approach
/// used by professional PDF converters like ConvertAPI and Adobe tools.
pub fn convert(
    input_path: &str,
    output_dir: &str,
    format: &str,
    dpi: u32,
    quality: u8,
    selected_pages: &[usize], // 1-indexed, empty = all pages
    show_progress: bool,
) -> Result<ConversionResult> {
    std::fs::create_dir_all(output_dir)
        .with_context(|| format!("Cannot create output directory: {}", output_dir))?;

    let stem = Path::new(input_path)
        .file_stem()
        .unwrap_or_default()
        .to_string_lossy()
        .to_string();

    // --- Determine total page count ---
    let total_pages = get_page_count_pdftoppm(input_path)
        .unwrap_or_else(|_| {
            // fallback: use pdfium just for count
            let pdfium = Pdfium::default();
            pdfium
                .load_pdf_from_file(input_path, None)
                .map(|d| d.pages().len() as usize)
                .unwrap_or(0)
        });

    // --- Determine which pages to process ---
    let page_numbers: Vec<usize> = if selected_pages.is_empty() {
        (1..=total_pages).collect()
    } else {
        selected_pages
            .iter()
            .filter(|&&p| p >= 1 && p <= total_pages)
            .copied()
            .collect()
    };

    let total = page_numbers.len();
    if total == 0 {
        anyhow::bail!("No valid pages to convert");
    }

    // --- Temp directory for pdftoppm intermediate files ---
    let tmp_prefix = format!("{}/{}_tmp", output_dir, stem);

    // --- Format flags for pdftoppm ---
    let fmt_flag = match format {
        "jpg" | "jpeg" => "-jpeg",
        _ => "-png",
    };

    // --- Run pdftoppm ---
    // If specific pages selected, run once per page. Otherwise run all at once.
    if selected_pages.is_empty() {
        // Convert all pages in one shot
        run_pdftoppm(input_path, &tmp_prefix, fmt_flag, dpi, quality, None, None)?;
    } else {
        // pdftoppm supports -f (first page) and -l (last page) but not arbitrary ranges.
        // For specific pages, run individually.
        for &page_num in &page_numbers {
            run_pdftoppm(
                input_path,
                &tmp_prefix,
                fmt_flag,
                dpi,
                quality,
                Some(page_num),
                Some(page_num),
            )?;
        }
    }

    // --- Collect and rename output files ---
    // pdftoppm outputs files like: <prefix>-001.png, <prefix>-002.png, ...
    let mut output_files: Vec<String> = Vec::new();
    let ext = match format {
        "jpg" | "jpeg" => "jpg",
        _ => "png",
    };

    for (idx, &page_num) in page_numbers.iter().enumerate() {
        // pdftoppm zero-pads based on total page count digits
        let digits = total_pages.to_string().len().max(1);
        let padded = format!("{:0>width$}", page_num, width = digits);
        let src = format!("{}-{}.{}", tmp_prefix, padded, ext);

        // Also try common padding widths if the file doesn't exist
        let src = if Path::new(&src).exists() {
            src
        } else {
            // Try different padding sizes (1-6 digits)
            (1..=6)
                .map(|w| format!("{}-{:0>width$}.{}", tmp_prefix, page_num, ext, width = w))
                .find(|p| Path::new(p).exists())
                .unwrap_or(src)
        };

        let dst = format!("{}/{}_page_{:03}.{}", output_dir, stem, page_num, ext);

        if Path::new(&src).exists() {
            std::fs::rename(&src, &dst)
                .with_context(|| format!("Cannot move {} to {}", src, dst))?;
            output_files.push(dst.clone());
        } else {
            eprintln!("Warning: expected output file not found: {}", src);
        }

        if show_progress {
            let progress = ProgressMsg {
                msg_type: "progress".to_string(),
                current: idx + 1,
                total,
            };
            println!("{}", serde_json::to_string(&progress).unwrap());
            let output_msg = OutputMsg {
                msg_type: "output".to_string(),
                file: dst,
            };
            println!("{}", serde_json::to_string(&output_msg).unwrap());
        }
    }

    // --- Cleanup any leftover tmp files ---
    // (in case pdftoppm produced extra pages we didn't ask for)
    let _ = std::fs::read_dir(output_dir).map(|entries| {
        for entry in entries.flatten() {
            let name = entry.file_name().to_string_lossy().to_string();
            if name.contains("_tmp-") {
                let _ = std::fs::remove_file(entry.path());
            }
        }
    });

    output_files.sort();

    Ok(ConversionResult {
        result_type: "result".to_string(),
        success: true,
        total_items: output_files.len(),
        output_files,
        error_code: None,
        error_message: None,
    })
}

/// Run pdftoppm for the given page range (None = all pages).
fn run_pdftoppm(
    input: &str,
    output_prefix: &str,
    fmt_flag: &str,
    dpi: u32,
    quality: u8,
    first_page: Option<usize>,
    last_page: Option<usize>,
) -> Result<()> {
    let mut cmd = Command::new("pdftoppm");
    cmd.arg(fmt_flag)
        .arg("-r")
        .arg(dpi.to_string())
        .arg("-aa")
        .arg("yes")      // Anti-aliasing for text
        .arg("-aaVector")
        .arg("yes");     // Anti-aliasing for vectors

    // JPEG quality (pdftoppm uses -jpegopt quality=N)
    if fmt_flag == "-jpeg" {
        cmd.arg("-jpegopt").arg(format!("quality={}", quality));
    }

    if let Some(f) = first_page {
        cmd.arg("-f").arg(f.to_string());
    }
    if let Some(l) = last_page {
        cmd.arg("-l").arg(l.to_string());
    }

    cmd.arg(input).arg(output_prefix);

    let output = cmd
        .output()
        .with_context(|| "Failed to run pdftoppm. Is poppler-utils installed?")?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        anyhow::bail!("pdftoppm failed: {}", stderr);
    }

    Ok(())
}

/// Get total page count via pdftoppm -l flag trick, or pdfinfo.
fn get_page_count_pdftoppm(input: &str) -> Result<usize> {
    // Use pdfinfo if available
    let output = Command::new("pdfinfo")
        .arg(input)
        .output();

    if let Ok(out) = output {
        let text = String::from_utf8_lossy(&out.stdout);
        for line in text.lines() {
            if line.starts_with("Pages:") {
                if let Some(n) = line.split_whitespace().nth(1) {
                    if let Ok(count) = n.parse::<usize>() {
                        return Ok(count);
                    }
                }
            }
        }
    }

    anyhow::bail!("Could not determine page count")
}
