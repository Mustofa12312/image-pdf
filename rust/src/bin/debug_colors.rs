/// Debug tool: render page 1 of a PDF and print the raw byte values
/// of the first 5x5 pixels so we can determine the exact byte order.
/// Usage: cargo run --bin debug_colors -- /path/to/test.pdf
use pdfium_render::prelude::*;

fn main() {
    let args: Vec<String> = std::env::args().collect();
    if args.len() < 2 {
        eprintln!("Usage: {} <path_to_pdf>", args[0]);
        std::process::exit(1);
    }

    let pdf_path = &args[1];
    println!("Opening: {}", pdf_path);

    let pdfium = Pdfium::default();
    let doc = pdfium.load_pdf_from_file(pdf_path, None).expect("Failed to open PDF");
    let page = doc.pages().get(0).expect("No pages");

    let bitmap = page.render_with_config(
        &PdfRenderConfig::new()
            .set_target_size(200, 200)
            .clear_before_rendering(true),
    ).expect("Render failed");

    let raw = bitmap.as_raw_bytes();
    println!("Total bytes: {}", raw.len());
    println!("Expected for BGRA 200x200: {}", 200 * 200 * 4);
    println!("Expected for BGR  200x200: {}", 200 * 200 * 3);

    // Bytes per pixel
    let bpp = raw.len() / (200 * 200);
    println!("Bytes per pixel: {}", bpp);

    // Print first 10 pixels in raw byte form
    println!("\n--- First 10 pixels (raw bytes) ---");
    for i in 0..10 {
        let off = i * bpp;
        if off + bpp <= raw.len() {
            let bytes: Vec<u8> = raw[off..off+bpp].to_vec();
            println!("Pixel {}: {:?}", i, bytes);
        }
    }

    // If 4 bytes per pixel (BGRA or RGBA):
    if bpp == 4 {
        println!("\n--- Interpretation assuming BGRA (PDFium default) ---");
        for i in 0..5 {
            let off = i * 4;
            let (b, g, r, a) = (raw[off], raw[off+1], raw[off+2], raw[off+3]);
            println!("Pixel {}: B={} G={} R={} A={} → RGB=({},{},{})", i, b, g, r, a, r, g, b);
        }

        println!("\n--- Interpretation assuming RGBA (alternative) ---");
        for i in 0..5 {
            let off = i * 4;
            let (r, g, b, a) = (raw[off], raw[off+1], raw[off+2], raw[off+3]);
            println!("Pixel {}: R={} G={} B={} A={} → RGB=({},{},{})", i, r, g, b, a, r, g, b);
        }
    }

    println!("\nDone! Compare the RGB values above with what you see in the original PDF.");
    println!("If the top-left area of page 1 is WHITE: pixel values should be near (255,255,255)");
    println!("If the top-left area is DARK (maroon/blue header): values should be low R or low B.");
}
