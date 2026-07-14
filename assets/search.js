(function () {
  const input = document.getElementById("search-input");
  const results = document.getElementById("search-results");
  if (!input || !results) return;

  let posts = [];
  let loaded = false;

  async function loadIndex() {
    if (loaded) return;
    try {
      const resp = await fetch("/search.json");
      posts = await resp.json();
      loaded = true;
    } catch (e) {
      posts = [];
    }
  }

  function highlight(text, query) {
    if (!query) return text;
    const re = new RegExp("(" + query.replace(/[.*+?^${}()|[\]\\]/g, "\\$&") + ")", "gi");
    return text.replace(re, "<mark>$1</mark>");
  }

  function search(query) {
    const q = query.toLowerCase().trim();
    if (!q) {
      results.innerHTML = "";
      return;
    }

    const words = q.split(/\s+/);
    const matched = posts.filter(function (post) {
      const haystack = (post.title + " " + post.excerpt + " " + post.categories.join(" ")).toLowerCase();
      return words.every(function (w) { return haystack.indexOf(w) !== -1; });
    });

    if (matched.length === 0) {
      results.innerHTML = '<div class="search-empty">No posts found</div>';
      return;
    }

    var html = "";
    matched.forEach(function (post) {
      html += '<a href="' + post.url + '" class="search-result">';
      html += '<span class="search-result-title">' + highlight(post.title, query) + '</span>';
      html += '<span class="search-result-meta">' + post.date;
      if (post.categories.length) {
        html += ' &middot; ' + post.categories.join(", ");
      }
      html += '</span>';
      html += '<span class="search-result-excerpt">' + highlight(post.excerpt, query) + '</span>';
      html += '</a>';
    });

    results.innerHTML = html;
  }

  loadIndex();

  input.addEventListener("input", function () {
    search(this.value);
  });
})();
