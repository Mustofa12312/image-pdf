use pdfium_render::prelude::*;
fn main() {
    let pdfium = Pdfium::default();
    let mut new_doc = pdfium.create_new_pdf().unwrap();
    let old_doc = pdfium.load_pdf_from_file("dummy.pdf", None).unwrap();
    // try to append
    new_doc.pages().copy_page_from_document(&old_doc, 0).unwrap();
    new_doc.save_to_file("out.pdf").unwrap();
}
