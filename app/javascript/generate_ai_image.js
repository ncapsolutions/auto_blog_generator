function initAiImageButtons() {
  const btn = document.getElementById("generate-image-btn");
  if (!btn || btn.dataset.bound) return; // prevent double bind
  btn.dataset.bound = true;

  btn.addEventListener("click", async (e) => {
    e.preventDefault();
    const spinner = document.getElementById("generate-image-spinner");
    const errorBox = document.getElementById("ai-image-error-message");
    const previewContainer = document.getElementById("ai-image-preview");
    const hiddenField = document.getElementById("post_ai_image_url");

    spinner.classList.remove("hidden");
    errorBox.classList.add("hidden");

    const titleInput = document.getElementById("post_title");
    const title = (titleInput ? titleInput.value : "").trim();

    if (!title) {
      errorBox.textContent =
        "Please enter a title first. AI needs a prompt to generate the image!";
      errorBox.classList.remove("hidden");
      spinner.classList.add("hidden");
      return;
    }

    try {
      const response = await fetch("/posts/generate_ai_image", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')
            .content,
        },
        body: JSON.stringify({ title }),
      });

      const data = await response.json();
      if (!response.ok || data.error)
        throw new Error(data.error || "Image generation failed");

      if (previewContainer) {
        previewContainer.innerHTML = `<img src="${data.image_url}" class="w-full h-64 object-cover rounded-lg mb-2">`;
      }

      // Clear manual file selection & set AI URL
      const fileInput = document.getElementById("post_image");
      if (fileInput) fileInput.value = "";

      if (hiddenField) hiddenField.value = data.image_url;
    } catch (err) {
      errorBox.textContent = err.message;
      errorBox.classList.remove("hidden");
    } finally {
      spinner.classList.add("hidden");
    }
  });

  // If user chooses a manual file, clear AI URL and preview
  const fileInput = document.getElementById("post_image");
  if (fileInput && !fileInput.dataset.bound) {
    fileInput.dataset.bound = true;
    fileInput.addEventListener("change", () => {
      const hiddenField = document.getElementById("post_ai_image_url");
      const previewContainer = document.getElementById("ai-image-preview");
      if (hiddenField) hiddenField.value = "";
      if (previewContainer) previewContainer.innerHTML = "";
    });
  }
}

// ✅ Only turbo:load is enough for Rails 7 (no DOMContentLoaded)
document.addEventListener("turbo:load", initAiImageButtons);
