mod pdf_to_image;
mod image_to_pdf;

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
    }
}
