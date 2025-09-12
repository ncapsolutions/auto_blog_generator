document.addEventListener("turbo:load", () => {
  const btn = document.getElementById("generate-description-btn");
  if (!btn) return;

  btn.addEventListener("click", async (e) => {
    e.preventDefault();

    const spinner = document.getElementById("generate-spinner");
    const errorBox = document.getElementById("ai-error-message");
    const textarea = document.getElementById("post_description");

    spinner.classList.remove("hidden");
    errorBox.classList.add("hidden");

    try {
      const title = document.getElementById("post_title").value.trim();
      if (!title) throw new Error("Please enter a title first.");

      const response = await fetch("/posts/generate_description", {
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
        throw new Error(data.error || "Description generation failed");

      // ✅ Insert AI text into CKEditor if available
      const editor = window.getCkeditor ? window.getCkeditor() : null;
      if (editor) {
        editor.setData(data.description);
      } else {
        textarea.value = data.description; // fallback
      }
    } catch (err) {
      errorBox.textContent = err.message;
      errorBox.classList.remove("hidden");
    } finally {
      spinner.classList.add("hidden");
    }
  });
});
