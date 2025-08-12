Qualtrics.SurveyEngine.addOnReady(function () {
  // 1-based loop index
  var currentLoop = parseInt("${lm://CurrentLoopNumber}", 10);

  // Total loops (set once in Survey Flow as Embedded Data, e.g., total_loops=6)
  // Falls back to 6 if not set.
  var totalLoops = parseInt("${e://Field/total_loops}", 10) || 6;
  var halfPoint = Math.ceil(totalLoops / 2);

  // Assign by position: first half = human, second half = ai
  var assigned = (currentLoop <= halfPoint) ? "human" : "ai";

  // Toggle UI (no jQuery)
  var humanEl = document.getElementById("human-source");
  var aiEl = document.getElementById("ai-source");

  if (humanEl && aiEl) {
    if (assigned === "human") {
      humanEl.style.display = "block";
      aiEl.style.display = "none";
    } else {
      aiEl.style.display = "block";
      humanEl.style.display = "none";
    }
  }

  // Record for data export (does not control display logic)
  Qualtrics.SurveyEngine.setJSEmbeddedData("current_source", assigned);
  Qualtrics.SurveyEngine.setJSEmbeddedData("interface_" + currentLoop + "_source", assigned);

  // Optional debug
  // console.log({ currentLoop, totalLoops, halfPoint, assigned });
});