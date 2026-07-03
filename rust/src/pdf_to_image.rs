use anyhow::{Context, Result};
use image::{ImageBuffer, Rgb};
use pdfium_render::prelude::*;
use rayon::prelude::*;
use serde::{Deserialize, Serialize};
use std::path::Path;
use std::sync::{Arc, Mutex};

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

pub fn convert(
    input_path: &str,
    output_dir: &str,
    format: &str,
    dpi: u32,
    quality: u8,
    selected_pages: &[usize], // 1-indexed, empty = all
    show_progress: bool,
) -> Result<ConversionResult> {
    std::fs::create_dir_all(output_dir)
        .with_context(|| format!("Cannot create output directory: {}", output_dir))?;

    let pdfium = Pdfium::default();
    let doc = pdfium
        .load_pdf_from_file(input_path, None)
        .with_context(|| "Failed to open PDF")?;

    let total_pages = doc.pages().len() as usize; // u16 → usize

    // Determine which pages to render
    let page_indices: Vec<usize> = if selected_pages.is_empty() {
        (0..total_pages).collect()
    } else {
        selected_pages
            .iter()
            .filter_map(|&p| {
                if p >= 1 && p <= total_pages {
                    Some(p - 1)
                } else {
                    None
                }
            })
            .collect()
    };

    let total = page_indices.len();
    let stem = Path::new(input_path)
        .file_stem()
        .unwrap_or_default()
        .to_string_lossy()
        .to_string();

    let output_files: Arc<Mutex<Vec<String>>> = Arc::new(Mutex::new(Vec::new()));
    let completed: Arc<Mutex<usize>> = Arc::new(Mutex::new(0));

    // Scale factor from DPI (PDFium renders at 72 DPI by default)
    let scale = dpi as f32 / 72.0;

    // Render pages sequentially (PDFium is not thread-safe for rendering)
    let render_results: Vec<(usize, Vec<u8>, u32, u32)> = page_indices
        .iter()
        .map(|&page_idx| -> Result<(usize, Vec<u8>, u32, u32)> {
            let page = doc.pages().get(page_idx as u16)?;
            let size = page.page_size();
            let width = (size.width().value as f32 * scale) as u32;
            let height = (size.height().value as f32 * scale) as u32;

            let bitmap = page.render_with_config(
                &PdfRenderConfig::new()
                    .set_target_size(width as i32, height as i32)
                    .clear_before_rendering(true), // Fixed method name
            )?;

            // Fixed: use as_raw_bytes() instead of deprecated as_bytes()
            let raw = bitmap.as_raw_bytes().to_vec();
            Ok((page_idx, raw, width, height))
        })
        .collect::<Result<Vec<_>>>()?;

    // Parallel image encoding & saving
    render_results
        .into_par_iter()
        .try_for_each(|(page_idx, raw, width, height)| -> Result<()> {
            let out_filename = format!(
                "{}/{}_page_{:03}.{}",
                output_dir,
                stem,
                page_idx + 1,
                format
            );

            // PDFium gives BGRA; convert to RGB
            let img: ImageBuffer<Rgb<u8>, Vec<u8>> = ImageBuffer::from_fn(width, height, |x, y| {
                let off = (y * width + x) as usize * 4;
                if off + 2 < raw.len() {
                    Rgb([raw[off + 2], raw[off + 1], raw[off]]) // BGRA → RGB
                } else {
                    Rgb([0, 0, 0])
                }
            });

            match format {
                "png" => img.save(&out_filename).with_context(|| format!("Cannot save {}", out_filename))?,
                "jpg" | "jpeg" => {
                    use image::codecs::jpeg::JpegEncoder;
                    let mut file = std::fs::File::create(&out_filename)?;
                    let mut encoder = JpegEncoder::new_with_quality(&mut file, quality);
                    encoder.encode_image(&img)?;
                }
                _ => anyhow::bail!("Unsupported format: {}", format),
            }

            let mut files = output_files.lock().unwrap();
            files.push(out_filename.clone());

            let mut count = completed.lock().unwrap();
            *count += 1;

            if show_progress {
                let progress = ProgressMsg {
                    msg_type: "progress".to_string(),
                    current: *count,
                    total,
                };
                println!("{}", serde_json::to_string(&progress).unwrap());
                let output_msg = OutputMsg {
                    msg_type: "output".to_string(),
                    file: out_filename,
                };
                println!("{}", serde_json::to_string(&output_msg).unwrap());
            }

            Ok(())
        })?;

    let files = output_files.lock().unwrap().clone();
    Ok(ConversionResult {
        result_type: "result".to_string(),
        success: true,
        total_items: files.len(),
        output_files: files,
        error_code: None,
        error_message: None,
    })
}
