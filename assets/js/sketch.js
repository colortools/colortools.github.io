let appWidth = 1280;
let appHeight = 900;
let pagePadding = 55;
let topPadding = 50;
let controlsStartY = 40;
let colorStartY = 130;
let squareSize = 150;
let squareGap = 20;
let currentPage = 0;
let colorsPerPage = 28;

let lightFont;
let boldFont;
let smallFont;
let smallFontStrong;

let table;
let colors = [];
let candidates = [];
let showCandidates = false;
let colorText = "";
let colorInput;
let nextButton;
let prevButton;
let resetButton;
let selectGroup;
let regex = /[a-fA-F0-9]+$/;

function preload() {
    smallFont = loadFont("assets/fonts/OpenSans-Light.ttf");
    lightFont = loadFont("assets/fonts/OpenSans-Regular.ttf");
    boldFont = loadFont("assets/fonts/OpenSans-Bold.ttf");

    table = loadTable('data/colors.csv', 'csv', 'header');
}

function setup() {
    let cnv = createCanvas(appWidth,appHeight);
    cnv.parent("sketchHolder");

    selectGroup = createSelect();
    selectGroup.position(pagePadding + 280, topPadding + controlsStartY);
    selectGroup.size(100);
    selectGroup.option('all');
    selectGroup.option('Blue');
    selectGroup.option('Yellow');
    selectGroup.option('Grey');
    selectGroup.option('Green');
    selectGroup.option('White');
    selectGroup.selected('all');
    selectGroup.changed(groupSelect);
    selectGroup.parent("sketchHolder");

    colorInput = createInput(colorText);
    colorInput.position(pagePadding + 75, topPadding + controlsStartY);
    colorInput.size(60);
    colorInput.input(colorInputEvent)
    colorInput.parent("sketchHolder");

    resetButton = createButton("Reset");
    resetButton.position(appWidth - pagePadding - 70, topPadding + controlsStartY);
    resetButton.size(70);
    resetButton.mousePressed(resetSearch);
    resetButton.parent("sketchHolder");    

    nextButton = createButton("Next");
    nextButton.position(appWidth - pagePadding - 155, topPadding + controlsStartY);
    nextButton.size(70);
    nextButton.mousePressed(nextPage);
    nextButton.parent("sketchHolder");
    nextButton.hide();

    prevButton = createButton("Previous");
    prevButton.position(appWidth - pagePadding - 240, topPadding + controlsStartY);
    prevButton.size(70);
    prevButton.mousePressed(prevPage);
    prevButton.parent("sketchHolder");
    prevButton.hide();

    loadData();
    findMatches();

    noLoop();
}

function groupSelect() {
    showCandidates = true;
    currentPage = 0;
    colorText = "";
    colorInput.value("");
    filterByGroup();
    draw();
}


function resetSearch() {
    showCandidates = false;
    currentPage = 0;
    colorText = "";
    colorInput.value("");
    selectGroup.selected('all');
    loadData();
    draw();
}

function nextPage() {
    currentPage++;
    draw();
}

function prevPage() {
    if(currentPage > 0) currentPage--;
    draw();
}

function colorInputEvent() {
    if(this.value().match(regex) || this.value() === "") {
        if(this.value().length<=6) {
            colorText = this.value();
        } else {
            this.value(colorText);
        }
        if(colorText.length == 6) {
            selectGroup.selected('all');
            findMatches();
            showCandidates = true;
        }
    } else {
        this.value(colorText);
    }
    draw();
}

function draw() {
    background(10);
    fill(255);
    textAlign(LEFT);
    textSize(30);
    textFont(boldFont);
    text("RAL MATCHING", pagePadding, topPadding);

    fill(255);
    textSize(12);
    textFont(lightFont);
    let labelRgb = "Search RGB";
    text(labelRgb, pagePadding, topPadding + controlsStartY + 19);
    text("Select Group", pagePadding + 200, topPadding + controlsStartY + 19);

    if(colorText.length == 6) {
        fill("#" + colorText);
        rect(pagePadding + textWidth(labelRgb) + 80, topPadding + controlsStartY, 30, 30);
    }    

    let startX = pagePadding;
    let startY = topPadding + colorStartY;
    let countColors = 0;

    let collection = colors;
    if(showCandidates) {
        collection = candidates;
    }

    collection.forEach(c => {
        countColors++;
        if(countColors - (colorsPerPage * currentPage) <= 0) return;
        if(countColors > colorsPerPage * (currentPage + 1)) {
            return;
        }
        noStroke();
        fill("#" + c.rgb);
        rect(startX, startY, squareSize, squareSize);
        
        textAlign(CENTER);
        if(c['dark'] === '1') {
            fill(0);
        } else {
            fill(255);
        }
        textSize(12);
        textFont(boldFont);
        text(c.nameDE, startX + (squareSize / 2), startY + (squareSize / 2) - 16);
        textFont(smallFont);
        text("RGB  #" + c.rgb, startX + (squareSize / 2), startY + (squareSize / 2));
        text("CMYK  " + c.cmyk, startX + (squareSize / 2), startY + (squareSize / 2) + 16);
        if(showCandidates) {
            text("Similarity  " + c.rank, startX + (squareSize / 2), startY + (squareSize / 2) + 32);
        }
        
        startX += squareSize + squareGap;
        if(startX + squareSize > (appWidth - pagePadding)) {
            startY += squareSize + squareGap;
            startX = pagePadding;
        }
    });

    if(currentPage == 0 || collection.length == 0) {
        prevButton.hide();        
    } else {
        prevButton.show();        
    }
    if(collection.length > (currentPage + 1) * colorsPerPage) {
        nextButton.show() 
    } else {
        nextButton.hide();
    }
}

function diffColors(c1, c2) {
    c1r = Number("0x" + c1.substring(0,2));
    c1g = Number("0x" + c1.substring(2,4));
    c1b = Number("0x" + c1.substring(4,6));

    c2r = Number("0x" + c2.substring(0,2));
    c2g = Number("0x" + c2.substring(2,4));
    c2b = Number("0x" + c2.substring(4,6));

    return Math.abs(c1r - c2r) + Math.abs(c1g - c2g) + Math.abs(c1b - c2b);
}

function compareRanks(c1, c2) {
    return c1['rank'] - c2['rank'];
}

function filterByGroup() {
    candidates.splice(0,candidates.length);
    colors.forEach(c => {
        if(selectGroup.value() == 'Blue' && c['range'].includes('Blautöne') ||
           selectGroup.value() == 'Yellow' && c['range'].includes('Gelbtöne') || 
           selectGroup.value() == 'Grey' && c['range'].includes('Grautöne') || 
           selectGroup.value() == 'Green' && c['range'].includes('Grüntöne') || 
           selectGroup.value() == 'Red' && c['range'].includes('Rottöne') || 
           selectGroup.value() == 'White' && c['range'].includes('Weiß-')
        ) {
            candidates.push(c);
        }
    });
}

function findMatches() {
    candidates.splice(0,candidates.length);
    
    colors.forEach(c => {
        diff = diffColors(c['rgb'], colorText);
        if(diff < 200) {
            c['rank'] = diff;
            candidates.push(c);
        }
    });

    candidates.sort(compareRanks);
    
    while (candidates.length > colorsPerPage) {
      candidates.pop();
    }

    draw();
}

function loadData() {
    colors.splice(0, colors.length);

    for (let r = 0; r < table.getRowCount(); r++) {
        const c = {
            "rgb": table.getString(r, 0),
            "cmyk": table.getString(r, 1),
            "url": table.getString(r, 2),
            "dark": table.getString(r, 3),
            "ral": table.getString(r, 4),
            "nameDE": table.getString(r, 5),
            "nameEN": table.getString(r, 6),
            "range": table.getString(r, 7)      
        };
        colors.push(c);
    }
  }