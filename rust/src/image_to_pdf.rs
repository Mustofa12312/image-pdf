use anyhow::{Context, Result};
use image::{DynamicImage, GenericImageView, ImageReader};
use serde::Serialize;
use std::io::Cursor;

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

// Points per inch for PDF
const PTS_PER_INCH: f32 = 72.0;

pub fn convert(
    inputs: &[(String, u32)], // (path, rotation_degrees)
    output_path: &str,
    paper: &str,
    orientation: &str,
    margin: f32,
    show_progress: bool,
) -> Result<ConversionResult> {
    use printpdf::*;
    use std::fs::File;
    use std::io::BufWriter;

    let total = inputs.len();

    // Parse paper dimensions in points
    let (pw, ph) = paper_size_pts(paper);
    let (page_w, page_h) = if orientation == "landscape" {
        (Mm(ph * 25.4 / 72.0), Mm(pw * 25.4 / 72.0))
    } else {
        (Mm(pw * 25.4 / 72.0), Mm(ph * 25.4 / 72.0))
    };

    // Create PDF document
    let (doc, page1, layer1) = PdfDocument::new("output", page_w, page_h, "Layer 1");

    for (i, (img_path, rotation)) in inputs.iter().enumerate() {
        if show_progress {
            let msg = ProgressMsg { msg_type: "progress".to_string(), current: i + 1, total };
            println!("{}", serde_json::to_string(&msg).unwrap());
        }

        let img = ImageReader::open(img_path)
            .with_context(|| format!("Cannot open image: {}", img_path))?
            .decode()
            .with_context(|| format!("Cannot decode image: {}", img_path))?;

        // Apply rotation
        let img = apply_rotation(img, *rotation);
        let (img_w, img_h) = img.dimensions();

        // Determine display page
        let (cur_page, cur_layer) = if i == 0 {
            (page1, layer1)
        } else {
            let (p, l) = doc.add_page(page_w, page_h, "Layer 1");
            (p, l)
        };

        let layer = doc.get_page(cur_page).get_layer(cur_layer);

        // Calculate image placement respecting margin
        let margin_mm = margin * 25.4 / PTS_PER_INCH;
        let avail_w = page_w.0 - 2.0 * margin_mm;
        let avail_h = page_h.0 - 2.0 * margin_mm;

        let img_aspect = img_w as f32 / img_h as f32;
        let avail_aspect = avail_w / avail_h;

        let (draw_w, draw_h) = if paper == "Original" {
            (img_w as f32 * 25.4 / 96.0, img_h as f32 * 25.4 / 96.0) // 96 DPI screen
        } else if img_aspect > avail_aspect {
            (avail_w, avail_w / img_aspect)
        } else {
            (avail_h * img_aspect, avail_h)
        };

        let x_offset = margin_mm + (avail_w - draw_w) / 2.0;
        let y_offset = margin_mm + (avail_h - draw_h) / 2.0;

        // Encode image to bytes for PDF embedding
        let mut buf = Cursor::new(Vec::new());
        img.write_to(&mut buf, image::ImageFormat::Png)?;
        let image_bytes = buf.into_inner();

        let pdf_img = printpdf::Image::from_dynamic_image(&img);
        pdf_img.add_to_layer(
            layer.clone(),
            printpdf::ImageTransform {
                translate_x: Some(Mm(x_offset)),
                translate_y: Some(Mm(y_offset)),
                scale_x: Some(draw_w / (img_w as f32 * 25.4 / 96.0)),
                scale_y: Some(draw_h / (img_h as f32 * 25.4 / 96.0)),
                ..Default::default()
            },
        );
    }

    // Save PDF
    let file = File::create(output_path).with_context(|| format!("Cannot create output: {}", output_path))?;
    doc.save(&mut BufWriter::new(file)).with_context(|| "Cannot write PDF")?;

    Ok(ConversionResult {
        result_type: "result".to_string(),
        success: true,
        total_items: 1,
        output_files: vec![output_path.to_string()],
        error_code: None,
        error_message: None,
    })
}

fn paper_size_pts(paper: &str) -> (f32, f32) {
    match paper {
        "A4" => (595.28, 841.89),
        "Letter" => (612.0, 792.0),
        _ => (595.28, 841.89), // Default to A4
    }
}

fn apply_rotation(img: DynamicImage, degrees: u32) -> DynamicImage {
    match degrees % 360 {
        90 => img.rotate90(),
        180 => img.rotate180(),
        270 => img.rotate270(),
        _ => img,
    }
}
