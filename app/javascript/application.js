// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "generate_description"
import "generate_ai_image";
import "generate_qa";
import "generate_keyword";
let ckeditorInstance; // 🔹 Global variable to hold editor

document.addEventListener("turbo:load", () => {
  const textarea = document.querySelector("#post_description");

  if (textarea) {
    if (textarea.dataset.ckeditorInitialized) return;

    ClassicEditor.create(textarea, {
      toolbar: [
        "heading",
        "|",
        "bold",
        "italic",
        "link",
        "bulletedList",
        "numberedList",
        "blockQuote",
        "undo",
        "redo",
      ],
    })
      .then((editor) => {
        textarea.dataset.ckeditorInitialized = true;
        ckeditorInstance = editor; // 🔹 Store globally

        // ✅ Keep textarea synced (so Rails submits it)
        editor.model.document.on("change:data", () => {
          textarea.value = editor.getData();
        });
      })
      .catch((error) => {
        console.error("CKEditor init error:", error);
      });
  }
});

// 🔹 Export CKEditor instance globally so AI script can access it
window.getCkeditor = () => ckeditorInstance;
