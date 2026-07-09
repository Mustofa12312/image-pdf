use anyhow::{Context, Result};
use pdfium_render::prelude::*;
use serde::Serialize;
use std::path::Path;

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

pub fn merge_pdfs(
    input_paths: &[String],
    output_path: &str,
    show_progress: bool,
) -> Result<ConversionResult> {
    let pdfium = Pdfium::default();
    let mut merged_doc = pdfium
        .create_new_pdf()
        .with_context(|| "Failed to create new PDF for merging")?;

    let total = input_paths.len();

    for (i, input_path) in input_paths.iter().enumerate() {
        let input_doc = pdfium
            .load_pdf_from_file(input_path, None)
            .with_context(|| format!("Failed to open PDF: {}", input_path))?;
        
        merged_doc
            .pages_mut()
            .append(&input_doc)
            .with_context(|| format!("Failed to append pages from {}", input_path))?;

        if show_progress {
            let progress = ProgressMsg {
                msg_type: "progress".to_string(),
                current: i + 1,
                total,
            };
            println!("{}", serde_json::to_string(&progress).unwrap());
        }
    }

    if let Some(parent) = Path::new(output_path).parent() {
        let _ = std::fs::create_dir_all(parent);
    }

    merged_doc
        .save_to_file(&Path::new(output_path))
        .with_context(|| format!("Failed to save merged PDF to {}", output_path))?;

    if show_progress {
        let output_msg = OutputMsg {
            msg_type: "output".to_string(),
            file: output_path.to_string(),
        };
        println!("{}", serde_json::to_string(&output_msg).unwrap());
    }

    Ok(ConversionResult {
        result_type: "result".to_string(),
        success: true,
        total_items: 1,
        output_files: vec![output_path.to_string()],
        error_code: None,
        error_message: None,
    })
}

pub fn extract_pages(
    input_path: &str,
    output_path: &str,
    pages_str: &str,
    show_progress: bool,
) -> Result<ConversionResult> {
    let pdfium = Pdfium::default();
    let source_doc = pdfium
        .load_pdf_from_file(input_path, None)
        .with_context(|| format!("Failed to open PDF: {}", input_path))?;
    
    let mut extracted_doc = pdfium
        .create_new_pdf()
        .with_context(|| "Failed to create new PDF for extraction")?;

    let mut page_indices: Vec<usize> = Vec::new();
    for part in pages_str.split(',') {
        let part = part.trim();
        if part.is_empty() {
            continue;
        }
        if let Some((start_str, end_str)) = part.split_once('-') {
            if let (Ok(start), Ok(end)) = (start_str.trim().parse::<usize>(), end_str.trim().parse::<usize>()) {
                if start <= end {
                    page_indices.extend(start..=end);
                } else {
                    page_indices.extend((end..=start).rev());
                }
            }
        } else if let Ok(num) = part.parse::<usize>() {
            page_indices.push(num);
        }
    }

    let total_source_pages = source_doc.pages().len() as usize;
    let total = page_indices.len();

    for (i, &page_number) in page_indices.iter().enumerate() {
        // user inputs 1-indexed page numbers
        if page_number < 1 || page_number > total_source_pages {
            continue;
        }
        let page_index = (page_number - 1) as u16;
        extracted_doc
            .pages_mut()
            .copy_page_from_document(&source_doc, page_index, i as u16)
            .with_context(|| format!("Failed to extract page {}", page_number))?;
        
        if show_progress {
            let progress = ProgressMsg {
                msg_type: "progress".to_string(),
                current: i + 1,
                total,
            };
            println!("{}", serde_json::to_string(&progress).unwrap());
        }
    }

    if let Some(parent) = Path::new(output_path).parent() {
        let _ = std::fs::create_dir_all(parent);
    }

    extracted_doc
        .save_to_file(&Path::new(output_path))
        .with_context(|| format!("Failed to save extracted PDF to {}", output_path))?;

    if show_progress {
        let output_msg = OutputMsg {
            msg_type: "output".to_string(),
            file: output_path.to_string(),
        };
        println!("{}", serde_json::to_string(&output_msg).unwrap());
    }

    Ok(ConversionResult {
        result_type: "result".to_string(),
        success: true,
        total_items: 1,
        output_files: vec![output_path.to_string()],
        error_code: None,
        error_message: None,
    })
}
