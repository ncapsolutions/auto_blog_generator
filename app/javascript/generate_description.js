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

      const keywordInputs = document.querySelectorAll(
        'input[name="post[keywords][]"]'
      );
      const linkInputs = document.querySelectorAll(
        'input[name="post[links][]"]'
      );

      const keywords = Array.from(keywordInputs).map((input) =>
        input.value.trim()
      );
      const links = Array.from(linkInputs).map((input) => input.value.trim());

      const response = await fetch("/posts/generate_description", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')
            .content,
        },
        body: JSON.stringify({ title, keywords, links }),
      });

      const data = await response.json();
      if (!response.ok || data.error)
        throw new Error(data.error || "Description generation failed");

      const editor = window.getCkeditor ? window.getCkeditor() : null;
      if (editor) {
        editor.setData(data.description);
      } else {
        textarea.value = data.description;
      }
    } catch (err) {
      errorBox.textContent = err.message;
      errorBox.classList.remove("hidden");
    } finally {
      spinner.classList.add("hidden");
    }
  });
});
