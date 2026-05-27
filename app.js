const canvas = document.querySelector("#previewCanvas");
const ctx = canvas.getContext("2d");

const imageInput = document.querySelector("#imageInput");
const downloadBtn = document.querySelector("#downloadBtn");
const sceneOptions = document.querySelector("#sceneOptions");
const frameOptions = document.querySelector("#frameOptions");
const paperOptions = document.querySelector("#paperOptions");
const ratioButtons = [...document.querySelectorAll(".ratio")];

const controls = {
  frameWidth: document.querySelector("#frameWidth"),
  cornerRadius: document.querySelector("#cornerRadius"),
  matWidth: document.querySelector("#matWidth"),
  smoothness: document.querySelector("#smoothness"),
  shadowDepth: document.querySelector("#shadowDepth"),
};

const scenes = [
  {
    id: "gallery",
    name: "Phòng triển lãm",
    preview: "linear-gradient(160deg, #f9f7f1 0 62%, #d8c7aa 62% 100%)",
    wall: ["#f9f7f1", "#ece6dc"],
    floor: ["#d8c7aa", "#bfa783"],
    trim: "#c9bda8",
    furniture: "bench",
  },
  {
    id: "living",
    name: "Phòng khách",
    preview: "linear-gradient(150deg, #dfe8e5 0 61%, #b88563 61% 100%)",
    wall: ["#dfe8e5", "#c9d8d4"],
    floor: ["#b88563", "#8a5b3e"],
    trim: "#9eb7b0",
    furniture: "sofa",
  },
  {
    id: "studio",
    name: "Studio tối",
    preview: "linear-gradient(145deg, #3d4240 0 62%, #8c7356 62% 100%)",
    wall: ["#3d4240", "#252927"],
    floor: ["#8c7356", "#4f3b2b"],
    trim: "#575d59",
    furniture: "lamp",
  },
  {
    id: "dining",
    name: "Bàn ăn",
    preview: "linear-gradient(150deg, #eee2d0 0 60%, #6d7d63 60% 100%)",
    wall: ["#eee2d0", "#dbc7aa"],
    floor: ["#6d7d63", "#3e4d3a"],
    trim: "#bfae91",
    furniture: "table",
  },
  {
    id: "paper",
    name: "Nền giấy",
    preview: "radial-gradient(circle at 30% 20%, #fff 0 20%, #e7ddc9 55%, #c7b18d 100%)",
    wall: ["#fbf7ef", "#e6dcc9"],
    floor: ["#cab58e", "#a78b61"],
    trim: "#d2c2a8",
    furniture: "plant",
  },
  {
    id: "ink",
    name: "Thủy mặc",
    preview: "linear-gradient(135deg, #f2f3ee 0%, #aab3aa 48%, #303734 100%)",
    wall: ["#f2f3ee", "#d4d9d2"],
    floor: ["#aab3aa", "#707c75"],
    trim: "#b6bdb5",
    furniture: "screen",
  },
];

const frames = [
  { id: "walnut", name: "Óc chó", base: "#5b3825", edge: "#2f1a10", shine: "#9d7254" },
  { id: "oak", name: "Sồi sáng", base: "#b68b54", edge: "#6d4b2f", shine: "#e2c08b" },
  { id: "black", name: "Đen mờ", base: "#202322", edge: "#050605", shine: "#555c58" },
  { id: "white", name: "Trắng", base: "#f2f0ea", edge: "#b7b3a9", shine: "#ffffff" },
  { id: "gold", name: "Vàng cổ", base: "#b8892d", edge: "#5e4318", shine: "#edce73" },
  { id: "steel", name: "Kim loại", base: "#717b81", edge: "#343b40", shine: "#c9d1d4" },
];

const papers = ["#f8f3e8", "#fffdf7", "#ece0c9", "#d8c7ad", "#eff1ec", "#222523"];

const state = {
  scene: scenes[0],
  frame: frames[0],
  paper: papers[0],
  ratio: "portrait",
  image: null,
};

function init() {
  renderSceneOptions();
  renderFrameOptions();
  renderPaperOptions();
  bindEvents();
  draw();
}

function renderSceneOptions() {
  sceneOptions.innerHTML = "";
  scenes.forEach((scene) => {
    const button = document.createElement("button");
    button.className = `option-tile ${scene.id === state.scene.id ? "active" : ""}`;
    button.type = "button";
    button.style.setProperty("--preview", scene.preview);
    button.innerHTML = `<span>${scene.name}</span>`;
    button.addEventListener("click", () => {
      state.scene = scene;
      renderSceneOptions();
      draw();
    });
    sceneOptions.append(button);
  });
}

function renderFrameOptions() {
  frameOptions.innerHTML = "";
  frames.forEach((frame) => {
    const button = document.createElement("button");
    button.className = `option-tile ${frame.id === state.frame.id ? "active" : ""}`;
    button.type = "button";
    button.style.setProperty(
      "--preview",
      `linear-gradient(135deg, ${frame.shine}, ${frame.base} 45%, ${frame.edge})`,
    );
    button.innerHTML = `<span>${frame.name}</span>`;
    button.addEventListener("click", () => {
      state.frame = frame;
      renderFrameOptions();
      draw();
    });
    frameOptions.append(button);
  });
}

function renderPaperOptions() {
  paperOptions.innerHTML = "";
  papers.forEach((paper) => {
    const button = document.createElement("button");
    button.className = `swatch ${paper === state.paper ? "active" : ""}`;
    button.type = "button";
    button.style.setProperty("--paper", paper);
    button.setAttribute("aria-label", `Màu giấy ${paper}`);
    button.addEventListener("click", () => {
      state.paper = paper;
      renderPaperOptions();
      draw();
    });
    paperOptions.append(button);
  });
}

function bindEvents() {
  Object.values(controls).forEach((input) => input.addEventListener("input", draw));

  ratioButtons.forEach((button) => {
    button.addEventListener("click", () => {
      state.ratio = button.dataset.ratio;
      ratioButtons.forEach((item) => item.classList.toggle("active", item === button));
      draw();
    });
  });

  imageInput.addEventListener("change", (event) => {
    const [file] = event.target.files;
    if (!file) return;

    const reader = new FileReader();
    reader.onload = () => {
      const image = new Image();
      image.onload = () => {
        state.image = image;
        draw();
      };
      image.src = reader.result;
    };
    reader.readAsDataURL(file);
  });

  downloadBtn.addEventListener("click", () => {
    const link = document.createElement("a");
    link.download = "frameit-preview.png";
    link.href = canvas.toDataURL("image/png", 1);
    link.click();
  });
}

function draw() {
  const width = canvas.width;
  const height = canvas.height;
  ctx.clearRect(0, 0, width, height);

  drawRoom(width, height);

  const artworkBox = getArtworkBox(width, height);
  const frameWidth = Number(controls.frameWidth.value);
  const matWidth = Number(controls.matWidth.value);
  const radius = Number(controls.cornerRadius.value);
  const shadowDepth = Number(controls.shadowDepth.value);

  drawFramePackage(artworkBox, frameWidth, matWidth, radius, shadowDepth);
}

function drawRoom(width, height) {
  const wallHeight = height * 0.66;
  const wallGradient = ctx.createLinearGradient(0, 0, width, wallHeight);
  wallGradient.addColorStop(0, state.scene.wall[0]);
  wallGradient.addColorStop(1, state.scene.wall[1]);
  ctx.fillStyle = wallGradient;
  ctx.fillRect(0, 0, width, wallHeight);

  drawWallTexture(width, wallHeight);

  const floorGradient = ctx.createLinearGradient(0, wallHeight, 0, height);
  floorGradient.addColorStop(0, state.scene.floor[0]);
  floorGradient.addColorStop(1, state.scene.floor[1]);
  ctx.fillStyle = floorGradient;
  ctx.fillRect(0, wallHeight, width, height - wallHeight);

  ctx.fillStyle = state.scene.trim;
  ctx.fillRect(0, wallHeight - 10, width, 18);

  drawFurniture(width, height, wallHeight);
}

function drawWallTexture(width, wallHeight) {
  ctx.save();
  ctx.globalAlpha = 0.09;
  ctx.strokeStyle = "#262b2a";
  ctx.lineWidth = 1;
  for (let y = 70; y < wallHeight - 35; y += 82) {
    ctx.beginPath();
    ctx.moveTo(0, y + Math.sin(y) * 7);
    ctx.bezierCurveTo(width * 0.3, y - 15, width * 0.62, y + 18, width, y - 4);
    ctx.stroke();
  }
  ctx.restore();
}

function drawFurniture(width, height, wallHeight) {
  ctx.save();
  ctx.globalAlpha = 0.92;

  if (state.scene.furniture === "bench") {
    roundedRect(width * 0.18, height * 0.8, width * 0.64, 42, 8);
    ctx.fillStyle = "rgba(72, 55, 39, 0.72)";
    ctx.fill();
    drawLegs(width, height, [0.24, 0.76]);
  }

  if (state.scene.furniture === "sofa") {
    roundedRect(width * 0.08, height * 0.77, width * 0.42, 92, 18);
    ctx.fillStyle = "rgba(54, 96, 90, 0.82)";
    ctx.fill();
    roundedRect(width * 0.11, height * 0.71, width * 0.34, 70, 14);
    ctx.fillStyle = "rgba(68, 117, 109, 0.86)";
    ctx.fill();
  }

  if (state.scene.furniture === "lamp") {
    ctx.strokeStyle = "rgba(236, 222, 188, 0.7)";
    ctx.lineWidth = 8;
    ctx.beginPath();
    ctx.moveTo(width * 0.82, height * 0.44);
    ctx.lineTo(width * 0.82, height * 0.84);
    ctx.stroke();
    ctx.fillStyle = "rgba(236, 222, 188, 0.9)";
    roundedRect(width * 0.77, height * 0.38, width * 0.1, 56, 8);
    ctx.fill();
  }

  if (state.scene.furniture === "table") {
    roundedRect(width * 0.58, height * 0.79, width * 0.28, 34, 8);
    ctx.fillStyle = "rgba(49, 55, 38, 0.86)";
    ctx.fill();
    drawLegs(width, height, [0.62, 0.82]);
  }

  if (state.scene.furniture === "plant") {
    ctx.fillStyle = "rgba(68, 91, 59, 0.78)";
    for (let i = 0; i < 8; i += 1) {
      ctx.beginPath();
      ctx.ellipse(width * 0.15 + i * 16, height * 0.74 - i * 9, 48, 14, -0.8 + i * 0.22, 0, Math.PI * 2);
      ctx.fill();
    }
    ctx.fillStyle = "rgba(112, 82, 54, 0.9)";
    roundedRect(width * 0.14, height * 0.82, width * 0.08, 58, 8);
    ctx.fill();
  }

  if (state.scene.furniture === "screen") {
    ctx.strokeStyle = "rgba(57, 63, 59, 0.6)";
    ctx.lineWidth = 3;
    for (let i = 0; i < 4; i += 1) {
      ctx.strokeRect(width * 0.72 + i * 42, height * 0.49, 38, height * 0.28);
    }
  }

  ctx.restore();
}

function drawLegs(width, height, positions) {
  ctx.strokeStyle = "rgba(38, 30, 24, 0.62)";
  ctx.lineWidth = 8;
  positions.forEach((x) => {
    ctx.beginPath();
    ctx.moveTo(width * x, height * 0.83);
    ctx.lineTo(width * (x - 0.015), height * 0.92);
    ctx.stroke();
  });
}

function getArtworkBox(width, height) {
  const ratios = {
    portrait: 0.72,
    square: 1,
    landscape: 1.38,
  };
  const aspect = state.image ? state.image.width / state.image.height : ratios[state.ratio];
  const maxW = width * 0.4;
  const maxH = height * 0.47;
  let artW = maxW;
  let artH = artW / aspect;
  if (artH > maxH) {
    artH = maxH;
    artW = artH * aspect;
  }

  return {
    x: width * 0.5 - artW / 2,
    y: height * 0.33 - artH / 2,
    w: artW,
    h: artH,
  };
}

function drawFramePackage(art, frameWidth, matWidth, radius, shadowDepth) {
  const outer = inflate(art, frameWidth + matWidth);
  const mat = inflate(art, matWidth);
  const shadow = shadowDepth / 100;

  ctx.save();
  ctx.shadowColor = `rgba(0, 0, 0, ${0.12 + shadow * 0.26})`;
  ctx.shadowBlur = 34 + shadow * 46;
  ctx.shadowOffsetY = 18 + shadow * 38;
  roundedRect(outer.x, outer.y, outer.w, outer.h, radius + 8);
  ctx.fillStyle = state.frame.edge;
  ctx.fill();
  ctx.restore();

  drawFrame(outer, mat, radius);
  drawMat(mat, art, radius);
  drawArtwork(art);
  drawGlass(outer, radius + 8);
}

function drawFrame(outer, inner, radius) {
  ctx.save();
  roundedRect(outer.x, outer.y, outer.w, outer.h, radius + 10);
  const gradient = ctx.createLinearGradient(outer.x, outer.y, outer.x + outer.w, outer.y + outer.h);
  gradient.addColorStop(0, state.frame.shine);
  gradient.addColorStop(0.22, state.frame.base);
  gradient.addColorStop(0.78, state.frame.edge);
  gradient.addColorStop(1, state.frame.shine);
  ctx.fillStyle = gradient;
  ctx.fill();

  roundedRect(inner.x, inner.y, inner.w, inner.h, Math.max(0, radius));
  ctx.globalCompositeOperation = "destination-out";
  ctx.fill();
  ctx.restore();

  ctx.save();
  ctx.strokeStyle = "rgba(255, 255, 255, 0.35)";
  ctx.lineWidth = 4;
  roundedRect(outer.x + 9, outer.y + 9, outer.w - 18, outer.h - 18, radius + 5);
  ctx.stroke();
  ctx.restore();
}

function drawMat(mat, art, radius) {
  ctx.save();
  roundedRect(mat.x, mat.y, mat.w, mat.h, Math.max(0, radius));
  ctx.fillStyle = state.paper;
  ctx.fill();

  drawPaperGrain(mat);

  roundedRect(art.x, art.y, art.w, art.h, Math.max(0, radius - 4));
  ctx.globalCompositeOperation = "destination-out";
  ctx.fill();
  ctx.restore();
}

function drawArtwork(art) {
  ctx.save();
  roundedRect(art.x, art.y, art.w, art.h, Math.max(0, Number(controls.cornerRadius.value) - 8));
  ctx.clip();

  ctx.fillStyle = state.paper;
  ctx.fillRect(art.x, art.y, art.w, art.h);

  if (state.image) {
    drawContainedImage(state.image, art);
  } else {
    drawPlaceholderArt(art);
  }

  applySmoothness(art);
  ctx.restore();
}

function drawContainedImage(image, box) {
  const imageAspect = image.width / image.height;
  const boxAspect = box.w / box.h;
  let drawW = box.w;
  let drawH = box.h;
  let x = box.x;
  let y = box.y;

  if (imageAspect > boxAspect) {
    drawH = box.h;
    drawW = drawH * imageAspect;
    x = box.x - (drawW - box.w) / 2;
  } else {
    drawW = box.w;
    drawH = drawW / imageAspect;
    y = box.y - (drawH - box.h) / 2;
  }

  ctx.drawImage(image, x, y, drawW, drawH);
}

function drawPlaceholderArt(box) {
  const artGradient = ctx.createLinearGradient(box.x, box.y, box.x + box.w, box.y + box.h);
  artGradient.addColorStop(0, "#e8d7be");
  artGradient.addColorStop(0.5, "#5f8178");
  artGradient.addColorStop(1, "#252b2a");
  ctx.fillStyle = artGradient;
  ctx.fillRect(box.x, box.y, box.w, box.h);

  ctx.strokeStyle = "rgba(255, 255, 255, 0.78)";
  ctx.lineWidth = Math.max(5, box.w * 0.018);
  for (let i = 0; i < 5; i += 1) {
    ctx.beginPath();
    ctx.moveTo(box.x + box.w * 0.16, box.y + box.h * (0.2 + i * 0.13));
    ctx.bezierCurveTo(
      box.x + box.w * 0.35,
      box.y + box.h * (0.05 + i * 0.18),
      box.x + box.w * 0.62,
      box.y + box.h * (0.36 + i * 0.08),
      box.x + box.w * 0.82,
      box.y + box.h * (0.18 + i * 0.12),
    );
    ctx.stroke();
  }
}

function drawPaperGrain(box) {
  ctx.save();
  ctx.globalAlpha = 0.09;
  ctx.fillStyle = "#1f2428";
  for (let i = 0; i < 360; i += 1) {
    const x = box.x + seededNoise(i * 13.13) * box.w;
    const y = box.y + seededNoise(i * 8.71 + 3) * box.h;
    ctx.fillRect(x, y, 1.3, 1.3);
  }
  ctx.restore();
}

function applySmoothness(box) {
  const smoothness = Number(controls.smoothness.value) / 100;
  if (smoothness < 0.04) return;

  ctx.save();
  ctx.globalAlpha = 0.28 * smoothness;
  const wrinkle = ctx.createLinearGradient(box.x, box.y, box.x + box.w, box.y);
  wrinkle.addColorStop(0, "rgba(255,255,255,0)");
  wrinkle.addColorStop(0.45, "rgba(255,255,255,0.8)");
  wrinkle.addColorStop(0.55, "rgba(255,255,255,0.14)");
  wrinkle.addColorStop(1, "rgba(255,255,255,0)");
  ctx.fillStyle = wrinkle;
  ctx.fillRect(box.x, box.y, box.w, box.h);
  ctx.restore();
}

function drawGlass(box, radius) {
  ctx.save();
  roundedRect(box.x, box.y, box.w, box.h, radius);
  ctx.clip();
  const glass = ctx.createLinearGradient(box.x, box.y, box.x + box.w, box.y + box.h);
  glass.addColorStop(0, "rgba(255,255,255,0.32)");
  glass.addColorStop(0.28, "rgba(255,255,255,0.02)");
  glass.addColorStop(0.45, "rgba(255,255,255,0.16)");
  glass.addColorStop(1, "rgba(255,255,255,0)");
  ctx.fillStyle = glass;
  ctx.fillRect(box.x, box.y, box.w, box.h);
  ctx.restore();
}

function inflate(rect, amount) {
  return {
    x: rect.x - amount,
    y: rect.y - amount,
    w: rect.w + amount * 2,
    h: rect.h + amount * 2,
  };
}

function roundedRect(x, y, width, height, radius) {
  const r = Math.min(radius, width / 2, height / 2);
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.arcTo(x + width, y, x + width, y + height, r);
  ctx.arcTo(x + width, y + height, x, y + height, r);
  ctx.arcTo(x, y + height, x, y, r);
  ctx.arcTo(x, y, x + width, y, r);
  ctx.closePath();
}

function seededNoise(value) {
  const x = Math.sin(value) * 10000;
  return x - Math.floor(x);
}

init();
