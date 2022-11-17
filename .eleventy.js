const { DateTime } = require("luxon");

module.exports = function(eleventyConfig) {
  // Output directory: _site
  eleventyConfig.addPassthroughCopy("assets");

  eleventyConfig.addFilter("formatDate", (d) => {
    return DateTime.fromJSDate(d).toUTC().toLocaleString(DateTime.DATE_MED);
  });

  eleventyConfig.addFilter("cacheBust", (url) => {
    const [urlPart, paramPart] = url.split("?");
    const params = new URLSearchParams(paramPart || "");
    params.set("v", DateTime.local().toFormat("X"));
    return `${urlPart}?${params}`;
  });

  eleventyConfig.addLiquidShortcode("formatAttunementMods", (mods) => {
    if (mods) {
      const keys = Object.keys(mods);
      keys.sort();
      const format = (n) => (n >= 0) ? `+${n}` : `${n}`;
      const joined = keys.map((k) => `${format(mods[k])} ${k}`).join(", ")

      return `(${joined})`;
    }
  });

  return {
    pathPrefix: "/monkey-see/"
  }
};
