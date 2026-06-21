(function () {
  "use strict";

  const config = window.EXAM_CONFIG || {};
  const app = document.getElementById("examApp");
  const alphabet = ["A", "B", "C", "D"];
  let bank = null;
  let store = null;

  function byId(id) {
    return document.getElementById(id);
  }

  function escapeHtml(value) {
    return String(value || "").replace(/[&<>"']/g, char => ({
      "&": "&amp;",
      "<": "&lt;",
      ">": "&gt;",
      "\"": "&quot;",
      "'": "&#39;"
    })[char]);
  }

  function storageKey() {
    return config.storageKey || ("steve_exam_" + (bank ? bank.course : "unknown"));
  }

  function freshStore() {
    return {
      version: 1,
      course: bank.course,
      dataVersion: bank.version,
      stats: {},
      history: [],
      current: null,
      finalPassedAt: null
    };
  }

  function loadStore() {
    try {
      const raw = localStorage.getItem(storageKey());
      if (!raw) return freshStore();
      const parsed = JSON.parse(raw);
      if (parsed.course !== bank.course || parsed.dataVersion !== bank.version) return freshStore();
      parsed.stats = parsed.stats || {};
      parsed.history = parsed.history || [];
      return parsed;
    } catch (error) {
      return freshStore();
    }
  }

  function saveStore() {
    localStorage.setItem(storageKey(), JSON.stringify(store));
  }

  function questionById(id) {
    return bank.questions.find(q => q.id === id);
  }

  function statFor(id) {
    if (!store.stats[id]) {
      store.stats[id] = { seen: 0, correct: 0, wrong: 0, streak: 0, last: 0 };
    }
    return store.stats[id];
  }

  function masteryFor(question) {
    const stat = store.stats[question.id];
    if (!stat || !stat.seen) return 0;
    const accuracy = stat.correct / stat.seen;
    const streak = Math.min(stat.streak || 0, 3) / 3;
    let value = accuracy * 0.48 + streak * 0.52;
    if (stat.wrong > 0 && stat.streak < 2) value *= 0.62;
    return Math.max(0, Math.min(1, value));
  }

  function summary() {
    const total = bank.questions.length;
    let seen = 0;
    let weak = 0;
    let failed = 0;
    let mastery = 0;
    for (const q of bank.questions) {
      const stat = store.stats[q.id];
      const score = masteryFor(q);
      mastery += score;
      if (stat && stat.seen) seen++;
      if (stat && stat.wrong > 0 && stat.streak < 2) failed++;
      if (score < 0.82) weak++;
    }
    return {
      total,
      seen,
      unseen: total - seen,
      failed,
      weak,
      masteryPct: Math.round((mastery / total) * 100)
    };
  }

  function randomNoise(seed) {
    let h = 2166136261;
    for (let i = 0; i < seed.length; i++) h = Math.imul(h ^ seed.charCodeAt(i), 16777619);
    h += h << 13; h ^= h >>> 7; h += h << 3; h ^= h >>> 17; h += h << 5;
    return (h >>> 0) / 4294967296;
  }

  function weightedScore(question, salt) {
    const stat = store.stats[question.id] || { seen: 0, correct: 0, wrong: 0, streak: 0, last: 0 };
    const mastery = masteryFor(question);
    let score = 0;
    if (!stat.seen) score += 70;
    if (stat.wrong > 0 && stat.streak < 2) score += 140 + stat.wrong * 18;
    score += (1 - mastery) * 90;
    score += Math.max(0, 5 - stat.seen) * 5;
    score -= Math.min(stat.streak, 3) * 10;
    score += randomNoise(question.id + salt) * 28;
    return score;
  }

  function chooseRound(mode) {
    const salt = String(Date.now()) + Math.random();
    if (mode === "final") {
      return bank.questions
        .slice()
        .sort((a, b) => randomNoise(a.id + salt) - randomNoise(b.id + salt))
        .map(q => q.id);
    }

    if (mode === "failed") {
      const failed = bank.questions
        .filter(q => {
          const stat = store.stats[q.id];
          return stat && stat.wrong > 0 && stat.streak < 2;
        })
        .sort((a, b) => weightedScore(b, salt) - weightedScore(a, salt));
      const fill = bank.questions
        .filter(q => !failed.includes(q))
        .sort((a, b) => weightedScore(b, salt) - weightedScore(a, salt));
      return failed.concat(fill).slice(0, bank.roundSize).map(q => q.id);
    }

    return bank.questions
      .slice()
      .sort((a, b) => weightedScore(b, salt) - weightedScore(a, salt))
      .slice(0, bank.roundSize)
      .map(q => q.id);
  }

  function startRound(mode) {
    store.current = {
      mode,
      ids: chooseRound(mode),
      answers: {},
      submitted: false,
      startedAt: Date.now(),
      result: null
    };
    saveStore();
    render();
    window.scrollTo({ top: 0, behavior: "smooth" });
  }

  function recordAnswer(questionId, optionIndex) {
    if (!store.current || store.current.submitted) return;
    store.current.answers[questionId] = optionIndex;
    saveStore();
    updateAnsweredCount();
  }

  function submitRound() {
    const current = store.current;
    if (!current || current.submitted) return;
    const unanswered = current.ids.filter(id => current.answers[id] == null);
    if (unanswered.length) {
      byId("roundMessage").textContent = unanswered.length + " unanswered question(s).";
      return;
    }

    let correct = 0;
    const failedIds = [];
    for (const id of current.ids) {
      const question = questionById(id);
      const chosen = current.answers[id];
      const ok = question.answers.includes(chosen);
      const stat = statFor(id);
      stat.seen += 1;
      stat.last = Date.now();
      if (ok) {
        stat.correct += 1;
        stat.streak += 1;
        correct += 1;
      } else {
        stat.wrong += 1;
        stat.streak = 0;
        failedIds.push(id);
      }
    }

    const score = correct / current.ids.length;
    current.submitted = true;
    current.completedAt = Date.now();
    current.result = { correct, total: current.ids.length, score, failedIds };
    store.history.unshift({
      mode: current.mode,
      correct,
      total: current.ids.length,
      score,
      completedAt: current.completedAt
    });
    store.history = store.history.slice(0, 20);
    if (current.mode === "final" && score >= bank.passThreshold) {
      store.finalPassedAt = current.completedAt;
    }
    saveStore();
    render();
    window.scrollTo({ top: 0, behavior: "smooth" });
  }

  function resetStats() {
    if (!confirm("Reset this exam's browser progress?")) return;
    store = freshStore();
    saveStore();
    render();
  }

  function renderShell() {
    app.innerHTML = [
      "<div class=\"wrap\">",
      "<div class=\"topbar\"><a class=\"back\" href=\"index.html\">Back to decks</a></div>",
      "<h1>" + escapeHtml(bank.title) + "</h1>",
      "<p class=\"lead\">" + escapeHtml(bank.description) + " All progress stays in this browser only.</p>",
      "<div class=\"metrics\" id=\"metrics\"></div>",
      "<div class=\"controls panel\">",
      "<button class=\"primary\" data-action=\"adaptive\">Adaptive 25</button>",
      "<button data-action=\"failed\">Failed drill</button>",
      "<button data-action=\"final\">Final 100</button>",
      "<button data-action=\"resume\">Resume</button>",
      "<button class=\"warn\" data-action=\"reset\">Reset stats</button>",
      "</div>",
      "<div id=\"notice\" class=\"notice\"></div>",
      "<div id=\"results\"></div>",
      "<form id=\"examForm\" class=\"panel\"></form>",
      "</div>"
    ].join("");

    app.addEventListener("click", event => {
      const button = event.target.closest("button[data-action]");
      if (!button) return;
      const action = button.dataset.action;
      if (action === "adaptive") startRound("adaptive");
      if (action === "failed") startRound("failed");
      if (action === "final") startRound("final");
      if (action === "resume") render();
      if (action === "reset") resetStats();
    });

    app.addEventListener("change", event => {
      const input = event.target;
      if (input && input.name && input.name.startsWith("q_")) {
        recordAnswer(input.name.slice(2), Number(input.value));
      }
    });
  }

  function renderMetrics() {
    const s = summary();
    byId("metrics").innerHTML = [
      metric(s.masteryPct + "%", "estimated mastery"),
      metric(s.seen + "/" + s.total, "questions seen"),
      metric(String(s.failed), "failed remembered"),
      metric(String(s.weak), "weak or unseen"),
      metric(store.finalPassedAt ? "passed" : "98%", "final target")
    ].join("");
  }

  function metric(value, label) {
    return "<div class=\"metric\"><b>" + escapeHtml(value) + "</b><span>" + escapeHtml(label) + "</span></div>";
  }

  function renderNotice() {
    const s = summary();
    const ready = s.masteryPct >= 98 && s.weak === 0 && s.unseen === 0;
    const current = store.current;
    let text = "<strong>Choose the exact best answer.</strong> The other choices are real course facts, not throwaway nonsense.";
    if (store.finalPassedAt) {
      text = "<strong>Final exam passed.</strong> Keep using adaptive rounds if any terms start to fade.";
    } else if (ready) {
      text = "<strong>Final exam is ready.</strong> Mastery is at 98% or better across the 100-question bank.";
    } else if (s.failed) {
      text = "<strong>" + s.failed + " failed question(s) are remembered.</strong> Failed drill and adaptive rounds will keep pulling them back until the streak recovers.";
    } else if (s.unseen) {
      text = "<strong>" + s.unseen + " question(s) have not been seen yet.</strong> Adaptive rounds will mix new coverage with weaker material.";
    }
    if (current && !current.submitted) {
      text += " Current round is saved across refresh.";
    }
    byId("notice").innerHTML = text;
  }

  function renderResults() {
    const slot = byId("results");
    const current = store.current;
    if (!current || !current.submitted || !current.result) {
      slot.innerHTML = "";
      return;
    }
    const result = current.result;
    const pct = Math.round(result.score * 100);
    const passedFinal = current.mode === "final" && result.score >= bank.passThreshold;
    const failedTerms = result.failedIds.map(id => questionById(id).focusTerm);
    slot.innerHTML = [
      "<section class=\"results panel\">",
      "<h2>" + escapeHtml(current.mode === "final" ? "Final exam result" : "Round result") + "</h2>",
      "<p><strong>" + result.correct + "/" + result.total + " (" + pct + "%)</strong>" + (passedFinal ? " - final target cleared." : "") + "</p>",
      failedTerms.length ? "<div class=\"failed-list\">" + failedTerms.map(term => "<span>" + escapeHtml(term) + "</span>").join("") + "</div>" : "<p>No misses in this round.</p>",
      "</section>"
    ].join("");
  }

  function renderQuestions() {
    const form = byId("examForm");
    const current = store.current;
    if (!current) {
      form.innerHTML = "";
      return;
    }

    const questions = current.ids.map(questionById);
    const submittedClass = current.submitted ? " submitted" : "";
    form.className = "panel" + submittedClass;
    form.innerHTML = [
      "<div class=\"round-head\">",
      "<div><h2>" + escapeHtml(current.mode === "final" ? "Final exam" : current.mode === "failed" ? "Failed drill" : "Adaptive round") + "</h2>",
      "<p id=\"roundMessage\"></p></div>",
      "</div>",
      questions.map((question, index) => renderQuestion(question, index, current)).join(""),
      "<div class=\"footer-actions\"><p id=\"answeredCount\"></p>",
      current.submitted ? "<button type=\"button\" class=\"primary\" data-action=\"adaptive\">Next adaptive round</button>" : "<button type=\"button\" class=\"primary\" id=\"submitRound\">Submit round</button>",
      "</div>"
    ].join("");

    const submit = byId("submitRound");
    if (submit) submit.addEventListener("click", submitRound);
    updateAnsweredCount();
  }

  function renderQuestion(question, index, current) {
    const chosen = current.answers[question.id];
    const correct = current.submitted && question.answers.includes(chosen);
    return [
      "<section class=\"question\" id=\"" + escapeHtml(question.id) + "\">",
      "<p class=\"qmeta\">" + (index + 1) + " / " + current.ids.length + " - " + escapeHtml(question.section) + "</p>",
      "<h3>" + escapeHtml(question.prompt) + "</h3>",
      "<div class=\"options\">",
      question.options.map((option, optionIndex) => renderOption(question, option, optionIndex, chosen, current.submitted)).join(""),
      "</div>",
      current.submitted ? "<div class=\"explanation\"><strong>" + (correct ? "Correct." : "Missed.") + "</strong> " + escapeHtml(question.explanation) + "</div>" : "",
      "</section>"
    ].join("");
  }

  function renderOption(question, option, optionIndex, chosen, submitted) {
    const isChosen = chosen === optionIndex;
    const isAnswer = question.answers.includes(optionIndex);
    const cls = submitted ? (isAnswer ? " correct" : isChosen ? " wrong" : "") : "";
    return [
      "<label class=\"option" + cls + "\">",
      "<input type=\"radio\" name=\"q_" + escapeHtml(question.id) + "\" value=\"" + optionIndex + "\"" + (isChosen ? " checked" : "") + (submitted ? " disabled" : "") + ">",
      "<span><strong>" + alphabet[optionIndex] + ".</strong> " + escapeHtml(option.text) + "</span>",
      "</label>"
    ].join("");
  }

  function updateAnsweredCount() {
    const current = store.current;
    const slot = byId("answeredCount");
    const msg = byId("roundMessage");
    if (!current || !slot) return;
    const answered = current.ids.filter(id => current.answers[id] != null).length;
    slot.textContent = current.submitted
      ? "Completed: " + current.result.correct + "/" + current.result.total
      : "Answered " + answered + "/" + current.ids.length;
    if (msg && !current.submitted) {
      msg.textContent = current.mode === "final"
        ? "Full repetition: all 100 questions, 98% pass target."
        : "25 questions selected from failures, weak stats, and new coverage.";
    }
  }

  function render() {
    renderMetrics();
    renderNotice();
    renderResults();
    renderQuestions();
  }

  async function boot() {
    if (!config.dataUrl) throw new Error("Missing exam data URL.");
    const response = await fetch(config.dataUrl, { cache: "no-cache" });
    if (!response.ok) throw new Error("Could not load " + config.dataUrl);
    bank = await response.json();
    store = loadStore();
    renderShell();
    render();
  }

  boot().catch(error => {
    app.innerHTML = "<div class=\"wrap\"><p class=\"notice\">Exam failed to load: " + escapeHtml(error.message) + "</p></div>";
  });
}());
