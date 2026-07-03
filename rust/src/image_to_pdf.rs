use anyhow::{Context, Result};
use image::DynamicImage;
use printpdf::{Image as PdfImage, ImageTransform, Mm, PdfDocument};
use serde::Serialize;
use std::fs::File;
use std::io::BufWriter;

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

pub fn convert(
    inputs: &[(String, u32)], // (path, rotation_degrees)
    output_path: &str,
    paper: &str,
    orientation: &str,
    margin: f32,         // in points
    show_progress: bool,
) -> Result<ConversionResult> {
    let total = inputs.len();
    if total == 0 {
        anyhow::bail!("No images provided");
    }

    // Paper dimensions in mm
    let (pw_mm, ph_mm): (f32, f32) = paper_size_mm(paper);
    let (page_w_mm, page_h_mm) = if orientation.to_lowercase() == "landscape" {
        (ph_mm, pw_mm)
    } else {
        (pw_mm, ph_mm)
    };

    // Margin: points → mm
    let margin_mm: f32 = margin * 25.4 / 72.0;

    // Create PDF — use first image for "Original" size
    let first_img = load_image(&inputs[0].0, inputs[0].1)?;
    let (fi_w, fi_h) = (first_img.width(), first_img.height());

    let (doc_w_mm, doc_h_mm): (f32, f32) = if paper == "Original" {
        (fi_w as f32 * 25.4 / 96.0, fi_h as f32 * 25.4 / 96.0)
    } else {
        (page_w_mm, page_h_mm)
    };

    let (doc, page1, layer1) = PdfDocument::new("PDF Converter Output", Mm(doc_w_mm), Mm(doc_h_mm), "Layer 1");

    for (i, (img_path, rotation)) in inputs.iter().enumerate() {
        if show_progress {
            let msg = ProgressMsg { msg_type: "progress".to_string(), current: i + 1, total };
            println!("{}", serde_json::to_string(&msg).unwrap());
        }

        let dyn_img = load_image(img_path, *rotation)?;
        let (img_w_px, img_h_px) = (dyn_img.width(), dyn_img.height());

        // Page size for this image
        let (cur_w_mm, cur_h_mm): (f32, f32) = if paper == "Original" {
            (img_w_px as f32 * 25.4 / 96.0, img_h_px as f32 * 25.4 / 96.0)
        } else {
            (page_w_mm, page_h_mm)
        };

        // Get layer for this page
        let layer = if i == 0 {
            doc.get_page(page1).get_layer(layer1)
        } else {
            let (p, l) = doc.add_page(Mm(cur_w_mm), Mm(cur_h_mm), "Layer 1");
            doc.get_page(p).get_layer(l)
        };

        // Available area after margin
        let avail_w = cur_w_mm - 2.0 * margin_mm;
        let avail_h = cur_h_mm - 2.0 * margin_mm;

        // Scale image to fit available area while keeping aspect ratio
        let (draw_w_mm, draw_h_mm): (f32, f32) = if paper == "Original" {
            (avail_w, avail_h)
        } else {
            let img_aspect = img_w_px as f32 / img_h_px as f32;
            let avail_aspect = avail_w / avail_h;
            if img_aspect > avail_aspect {
                (avail_w, avail_w / img_aspect)
            } else {
                (avail_h * img_aspect, avail_h)
            }
        };

        let x_off = margin_mm + (avail_w - draw_w_mm) / 2.0;
        let y_off = margin_mm + (avail_h - draw_h_mm) / 2.0;

        // DPI for the image: we want img_w_px pixels = draw_w_mm mm
        // DPI = px / (mm / 25.4) = px * 25.4 / mm
        let render_dpi = img_w_px as f32 * 25.4 / draw_w_mm;

        // Build printpdf Image using from_dynamic_image (requires embedded_images feature)
        let pdf_img = PdfImage::from_dynamic_image(&dyn_img);

        pdf_img.add_to_layer(
            layer,
            ImageTransform {
                translate_x: Some(Mm(x_off)),
                translate_y: Some(Mm(y_off)),
                scale_x: None,
                scale_y: None,
                rotate: None,
                dpi: Some(render_dpi),
            },
        );
    }

    let file = File::create(output_path)
        .with_context(|| format!("Cannot create: {}", output_path))?;
    doc.save(&mut BufWriter::new(file))
        .with_context(|| "Cannot save PDF")?;

    Ok(ConversionResult {
        result_type: "result".to_string(),
        success: true,
        total_items: 1,
        output_files: vec![output_path.to_string()],
        error_code: None,
        error_message: None,
    })
}

fn load_image(path: &str, rotation: u32) -> Result<DynamicImage> {
    let img = image::io::Reader::open(path)
        .with_context(|| format!("Cannot open: {}", path))?
        .decode()
        .with_context(|| format!("Cannot decode: {}", path))?;

    Ok(match rotation % 360 {
        90 => img.rotate90(),
        180 => img.rotate180(),
        270 => img.rotate270(),
        _ => img,
    })
}

fn paper_size_mm(paper: &str) -> (f32, f32) {
    match paper {
        "A4" => (210.0, 297.0),
        "Letter" => (215.9, 279.4),
        _ => (210.0, 297.0),
    }
}
