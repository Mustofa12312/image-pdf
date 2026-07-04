mod pdf_to_image;
mod image_to_pdf;
mod pdf_manipulation;

use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(name = "pdf_converter_engine", version = "1.0.0", about = "PDF ↔ Image Converter Engine")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Get PDF info (page count and dimensions)
    Info {
        #[arg(long)]
        input: String,
    },
    /// Convert PDF pages to images
    Pdf2img {
        #[arg(long)]
        input: String,
        #[arg(long)]
        output_dir: String,
        #[arg(long, default_value = "png")]
        format: String,
        #[arg(long, default_value_t = 300)]
        dpi: u32,
        #[arg(long, default_value_t = 90)]
        quality: u8,
        /// Comma-separated page numbers (1-indexed). Empty = all pages.
        #[arg(long, default_value = "")]
        pages: String,
        /// Emit JSON progress lines to stdout
        #[arg(long, default_value_t = false)]
        progress: bool,
    },
    /// Convert images to PDF
    Img2pdf {
        /// Format: "path:rotation_degrees" e.g. "/img.png:90"
        #[arg(long, num_args = 1..)]
        inputs: Vec<String>,
        #[arg(long)]
        output: String,
        #[arg(long, default_value = "A4")]
        paper: String,
        #[arg(long, default_value = "portrait")]
        orientation: String,
        #[arg(long, default_value_t = 0.0)]
        margin: f32,
        #[arg(long, default_value_t = false)]
        progress: bool,
    },
    /// Merge multiple PDFs into one
    MergePdf {
        #[arg(long, num_args = 1..)]
        inputs: Vec<String>,
        #[arg(long)]
        output: String,
        #[arg(long, default_value_t = false)]
        progress: bool,
    },
    /// Extract specific pages from a PDF
    ExtractPdf {
        #[arg(long)]
        input: String,
        #[arg(long)]
        output: String,
        /// Comma-separated page numbers (1-indexed)
        #[arg(long)]
        pages: String,
        #[arg(long, default_value_t = false)]
        progress: bool,
    },
    /// Convert Word to Images (Requires LibreOffice)
    Word2img {
        #[arg(long)]
        input: String,
        #[arg(long)]
        output_dir: String,
        #[arg(long, default_value = "png")]
        format: String,
        #[arg(long, default_value_t = 300)]
        dpi: u32,
        #[arg(long, default_value_t = 90)]
        quality: u8,
        #[arg(long, default_value_t = false)]
        progress: bool,
    },
}

fn main() {
    let cli = Cli::parse();
    match cli.command {
        Commands::Info { input } => {
            match pdf_to_image::get_pdf_info(&input) {
                Ok(pages) => {
                    let json = serde_json::to_string(&pages).unwrap_or_else(|_| "[]".to_string());
                    println!("{}", json);
                }
                Err(e) => {
                    eprintln!("Error: {}", e);
                    std::process::exit(1);
                }
            }
        }
        Commands::Pdf2img { input, output_dir, format, dpi, quality, pages, progress } => {
            let selected: Vec<usize> = if pages.is_empty() {
                vec![]
            } else {
                pages.split(',').filter_map(|s| s.trim().parse::<usize>().ok()).collect()
            };
            match pdf_to_image::convert(&input, &output_dir, &format, dpi, quality, &selected, progress) {
                Ok(result) => {
                    let json = serde_json::to_string(&result).unwrap_or_else(|_| "{}".to_string());
                    println!("{}", json);
                }
                Err(e) => {
                    eprintln!("{}", e);
                    std::process::exit(1);
                }
            }
        }
        Commands::Img2pdf { inputs, output, paper, orientation, margin, progress } => {
            let parsed: Vec<(String, u32)> = inputs.iter().map(|s| {
                let parts: Vec<&str> = s.splitn(2, ':').collect();
                let path = parts[0].to_string();
                let rot = parts.get(1).and_then(|r| r.parse().ok()).unwrap_or(0u32);
                (path, rot)
            }).collect();
            match image_to_pdf::convert(&parsed, &output, &paper, &orientation, margin, progress) {
                Ok(result) => {
                    let json = serde_json::to_string(&result).unwrap_or_else(|_| "{}".to_string());
                    println!("{}", json);
                }
                Err(e) => {
                    eprintln!("{}", e);
                    std::process::exit(1);
                }
            }
        }
        Commands::MergePdf { inputs, output, progress } => {
            match pdf_manipulation::merge_pdfs(&inputs, &output, progress) {
                Ok(result) => {
                    let json = serde_json::to_string(&result).unwrap_or_else(|_| "{}".to_string());
                    println!("{}", json);
                }
                Err(e) => {
                    eprintln!("{}", e);
                    std::process::exit(1);
                }
            }
        }
        Commands::ExtractPdf { input, output, pages, progress } => {
            match pdf_manipulation::extract_pages(&input, &output, &pages, progress) {
                Ok(result) => {
                    let json = serde_json::to_string(&result).unwrap_or_else(|_| "{}".to_string());
                    println!("{}", json);
                }
                Err(e) => {
                    eprintln!("{}", e);
                    std::process::exit(1);
                }
            }
        }
        Commands::Word2img { input, output_dir, format, dpi, quality, progress } => {
            let libreoffice = if cfg!(windows) {
                "soffice"
            } else {
                "libreoffice"
            };

            let temp_dir = std::env::temp_dir();
            let timestamp = std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).unwrap().as_millis();
            let temp_out = temp_dir.join(format!("word2img_{}", timestamp));
            let _ = std::fs::create_dir_all(&temp_out);

            let status = std::process::Command::new(libreoffice)
                .args(&[
                    "--headless",
                    "--convert-to", "pdf",
                    &input,
                    "--outdir", temp_out.to_str().unwrap()
                ])
                .status();

            match status {
                Ok(s) if s.success() => {
                    let input_path = std::path::Path::new(&input);
                    let pdf_path = temp_out.join(input_path.file_stem().unwrap()).with_extension("pdf");
                    if pdf_path.exists() {
                        match pdf_to_image::convert(pdf_path.to_str().unwrap(), &output_dir, &format, dpi, quality, &[], progress) {
                            Ok(result) => {
                                let json = serde_json::to_string(&result).unwrap_or_else(|_| "{}".to_string());
                                println!("{}", json);
                            }
                            Err(e) => {
                                eprintln!("{}", e);
                                let _ = std::fs::remove_dir_all(&temp_out);
                                std::process::exit(1);
                            }
                        }
                    } else {
                        eprintln!("Error: LibreOffice succeeded but PDF was not found.");
                        let _ = std::fs::remove_dir_all(&temp_out);
                        std::process::exit(1);
                    }
                }
                Ok(s) => {
                    eprintln!("Error: LibreOffice exited with status {}", s);
                    let _ = std::fs::remove_dir_all(&temp_out);
                    std::process::exit(1);
                }
                Err(e) => {
                    eprintln!("Error: Failed to run LibreOffice (is it installed and in PATH?). {}", e);
                    let _ = std::fs::remove_dir_all(&temp_out);
                    std::process::exit(1);
                }
            }
            let _ = std::fs::remove_dir_all(&temp_out);
        }
    }
}
