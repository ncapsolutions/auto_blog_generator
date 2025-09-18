document.addEventListener("turbo:load", () => {
  const generateQaBtn = document.getElementById("generate-qa-btn");
  const addQaBtn = document.getElementById("add-qa-btn");
  const qaContainer = document.getElementById("qa-container");
  const spinner = document.getElementById("generate-qa-spinner");
  const titleField = document.getElementById("post_title");

  if (!generateQaBtn || !addQaBtn || !qaContainer || !spinner || !titleField)
    return;

  const MIN_QA = 3;
  const MAX_QA = 5;

  // Attach remove buttons to existing rows
  qaContainer.querySelectorAll(".remove-qa").forEach((btn) => {
    btn.addEventListener("click", () => {
      const rows = qaContainer.querySelectorAll(".qa-row");
      if (rows.length > 3) {
        // <- enforce minimum 3 rows
        btn.closest(".qa-row").remove();
      } else {
        alert("At least 3 Q&A rows are required.");
      }
    });
  });

  function addQaRow(q = "", a = "") {
    const currentRows = qaContainer.querySelectorAll(".qa-row").length;
    if (currentRows >= MAX_QA) {
      alert(`Maximum ${MAX_QA} Q&A allowed.`);
      return;
    }

    const div = document.createElement("div");
    div.classList.add("flex", "space-x-2", "mt-1", "qa-row");
    div.innerHTML = `
      <input type="text" name="post[questions][]" value="${q}" placeholder="Question" class="mt-1 block w-1/2 rounded-lg border-gray-300 shadow-sm p-2 border" required>
      <input type="text" name="post[answers][]" value="${a}" placeholder="Answer" class="mt-1 block w-1/2 rounded-lg border-gray-300 shadow-sm p-2 border" required>
      <button type="button" class="remove-qa text-red-600 hover:text-red-800 font-medium px-2 rounded">Remove</button>
    `;
    qaContainer.insertBefore(div, addQaBtn);

    div
      .querySelector(".remove-qa")
      .addEventListener("click", () => div.remove());
  }

  // Manual add Q&A
  addQaBtn.addEventListener("click", () => addQaRow());

  // AI Generate Q&A
  generateQaBtn.addEventListener("click", async (e) => {
    e.preventDefault();

    spinner.classList.remove("hidden");

    const title = titleField.value.trim();
    if (!title) {
      alert("Please enter a title first.");
      spinner.classList.add("hidden");
      return;
    }

    const keywordInputs = document.querySelectorAll(
      'input[name="post[keywords][]"]'
    );
    const keywords = Array.from(keywordInputs).map((input) =>
      input.value.trim()
    );

    try {
      const response = await fetch("/posts/generate_qa", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')
            .content,
        },
        body: JSON.stringify({ title, keywords }),
      });

      const data = await response.json();

      if (!response.ok || !data.qa || data.qa.length === 0) {
        throw new Error(
          data.error || "No Q&A generated. Try a different title."
        );
      }

      // Clear existing rows
      qaContainer.querySelectorAll(".qa-row").forEach((row) => row.remove());

      // Add generated Q&A
      data.qa.slice(0, MAX_QA).forEach((item) => addQaRow(item.q, item.a));

      // Ensure minimum Q&A rows
      while (qaContainer.querySelectorAll(".qa-row").length < MIN_QA)
        addQaRow();
    } catch (err) {
      console.error(err);
      alert(err.message);
    } finally {
      spinner.classList.add("hidden");
    }
  });
});
