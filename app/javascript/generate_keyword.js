document.addEventListener("turbo:load", () => {
  const addKeywordBtn = document.getElementById("add-keyword-btn");
  const rowsContainer = document.getElementById("keywords-rows");
  if (!addKeywordBtn || !rowsContainer) return;

  const MIN_ROWS = 3;
  const MAX_ROWS = 5;

  function isValidURL(str) {
    try {
      new URL(str);
      return true;
    } catch (_) {
      return false;
    }
  }

  // Attach remove listener
  function attachRemoveListener(btn) {
    btn.addEventListener("click", () => {
      const rows = rowsContainer.querySelectorAll(".keyword-row");
      if (rows.length > 1) btn.closest(".keyword-row").remove();
      else alert("At least one keyword/link is required.");
    });
  }

  // Attach to existing remove buttons
  rowsContainer
    .querySelectorAll(".remove-keyword")
    .forEach(attachRemoveListener);

  // Ensure minimum rows on page load
  const currentRows = rowsContainer.querySelectorAll(".keyword-row").length;
  for (let i = currentRows; i < MIN_ROWS; i++) {
    const div = document.createElement("div");
    div.classList.add("flex", "space-x-2", "mt-1", "keyword-row");
    div.innerHTML = `
      <input type="text" name="post[keywords][]" placeholder="Keyword" class="flex-1 rounded-lg border-gray-300 p-2 border" required>
      <input type="text" name="post[links][]" placeholder="Link" class="flex-1 rounded-lg border-gray-300 p-2 border" required>
      <button type="button" class="remove-keyword text-red-600 px-2 rounded">Remove</button>
    `;
    rowsContainer.appendChild(div);
    attachRemoveListener(div.querySelector(".remove-keyword"));
  }

  // Add new row
  addKeywordBtn.addEventListener("click", () => {
    const currentRows = rowsContainer.querySelectorAll(".keyword-row").length;
    if (currentRows >= MAX_ROWS) {
      alert(`Maximum ${MAX_ROWS} keywords allowed.`);
      return;
    }

    const div = document.createElement("div");
    div.classList.add("flex", "space-x-2", "mt-1", "keyword-row");
    div.innerHTML = `
      <input type="text" name="post[keywords][]" placeholder="Keyword" class="flex-1 rounded-lg border-gray-300 p-2 border" required>
      <input type="text" name="post[links][]" placeholder="Link" class="flex-1 rounded-lg border-gray-300 p-2 border" required>
      <button type="button" class="remove-keyword text-red-600 px-2 rounded">Remove</button>
    `;
    rowsContainer.appendChild(div);
    attachRemoveListener(div.querySelector(".remove-keyword"));
  });

  // Validate URLs on submit
  const form = document.querySelector("form");
  form.addEventListener("submit", (e) => {
    const links = rowsContainer.querySelectorAll('input[name="post[links][]"]');
    for (const link of links) {
      if (!isValidURL(link.value.trim())) {
        alert("Please enter valid URLs for all link fields.");
        link.focus();
        e.preventDefault();
        return false;
      }
    }
  });
});
