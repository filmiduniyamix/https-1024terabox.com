#!/bin/bash

# Create directories
mkdir -p routes controllers utils public

# Create package.json
cat > package.json << 'EOF'
{
  "name": "terabox-downloader",
  "version": "1.0.0",
  "description": "Web-based downloader for 1024terabox.com using external API",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "axios": "^1.6.0",
    "cors": "^2.8.5",
    "dotenv": "^16.3.1",
    "express": "^4.18.2",
    "morgan": "^1.10.0"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  }
}
EOF

# Create server.js
cat > server.js << 'EOF'
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const apiRoutes = require('./routes/api');
const { errorHandler } = require('./utils/errorHandler');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use(morgan('dev'));
app.use(express.static('public'));

app.use('/api', apiRoutes);

app.use(errorHandler);

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
EOF

# Create routes/api.js
cat > routes/api.js << 'EOF'
const express = require('express');
const { resolveUrl } = require('../controllers/resolveController');
const router = express.Router();

router.post('/resolve', resolveUrl);

module.exports = router;
EOF

# Create controllers/resolveController.js
cat > controllers/resolveController.js << 'EOF'
const axios = require('axios');
const { logger } = require('../utils/logger');

const resolveUrl = async (req, res, next) => {
  const startTime = Date.now();
  try {
    const { url } = req.body;
    if (!url || !url.includes('1024terabox.com')) {
      return res.status(400).json({ status: 'error', message: 'Invalid 1024terabox URL' });
    }

    const apiBaseUrl = 'https://terabox-dl-9c39e76a6aa9.herokuapp.com/api';
    const response = await axios.get(`${apiBaseUrl}?url=${encodeURIComponent(url)}`, {
      timeout: 10000
    });

    const apiData = response.data;

    if (apiData.status !== 'success') {
      throw new Error(apiData.message || 'External API returned an error');
    }

    const responseTime = Date.now() - startTime;

    res.json({
      status: 'success',
      filename: apiData.filename || 'Unknown file',
      size: apiData.size || 'Unknown size',
      thumbnail: apiData.thumbs?.url3 || apiData.thumbs?.url1 || '',
      response_time: apiData.response_time || `${responseTime}ms`,
      url1: apiData.download || '',
      url2: '',
      url3: ''
    });

  } catch (error) {
    logger.error(`Resolve error: ${error.message}`);
    next(new Error('Failed to fetch file information. The link may be invalid or the external service is down.'));
  }
};

module.exports = { resolveUrl };
EOF

# Create utils/logger.js
cat > utils/logger.js << 'EOF'
const logger = {
  info: (msg) => console.log(`[INFO] ${new Date().toISOString()} - ${msg}`),
  error: (msg) => console.error(`[ERROR] ${new Date().toISOString()} - ${msg}`)
};

module.exports = { logger };
EOF

# Create utils/errorHandler.js
cat > utils/errorHandler.js << 'EOF'
const { logger } = require('./logger');

const errorHandler = (err, req, res, next) => {
  logger.error(`Unhandled error: ${err.stack || err.message}`);
  res.status(500).json({
    status: 'error',
    message: err.message || 'Internal server error'
  });
};

module.exports = { errorHandler };
EOF

# Create public/index.html
cat > public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>1024Terabox Downloader</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="container">
        <h1>1024Terabox Downloader</h1>
        <p>Paste your 1024terabox.com link below</p>
        
        <div class="input-group">
            <input type="url" id="urlInput" placeholder="https://1024terabox.com/s/..." required>
            <button id="submitBtn">Resolve</button>
        </div>

        <div id="loader" class="loader hidden"></div>
        
        <div id="error" class="error hidden"></div>

        <div id="result" class="result hidden">
            <img id="thumbnail" src="" alt="Thumbnail">
            <h3 id="filename"></h3>
            <p id="fileSize" style="color: #aaa; margin-bottom: 15px;"></p>
            <div class="download-buttons" id="downloadButtons"></div>
        </div>

        <div class="social-links">
            <a href="https://t.me/yourchannel" target="_blank">Telegram</a>
            <a href="https://instagram.com/yourpage" target="_blank">Instagram</a>
            <a href="https://youtube.com/@yourchannel" target="_blank">YouTube</a>
        </div>
    </div>

    <script src="script.js"></script>
</body>
</html>
EOF

# Create public/style.css
cat > public/style.css << 'EOF'
/* Dark theme */
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
    background: #1a1a1a;
    color: #e0e0e0;
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 20px;
}

.container {
    max-width: 600px;
    width: 100%;
    background: #2d2d2d;
    border-radius: 12px;
    padding: 30px;
    box-shadow: 0 8px 20px rgba(0,0,0,0.5);
}

h1 {
    text-align: center;
    margin-bottom: 10px;
    color: #bb86fc;
}

p {
    text-align: center;
    margin-bottom: 25px;
    color: #aaa;
}

.input-group {
    display: flex;
    gap: 10px;
    margin-bottom: 20px;
}

#urlInput {
    flex: 1;
    padding: 12px 16px;
    background: #3d3d3d;
    border: 1px solid #555;
    border-radius: 8px;
    color: #fff;
    font-size: 16px;
    outline: none;
    transition: border 0.2s;
}

#urlInput:focus {
    border-color: #bb86fc;
}

#submitBtn {
    padding: 12px 24px;
    background: #bb86fc;
    color: #000;
    border: none;
    border-radius: 8px;
    font-size: 16px;
    font-weight: 600;
    cursor: pointer;
    transition: background 0.2s;
}

#submitBtn:hover {
    background: #a06cd5;
}

#submitBtn:disabled {
    opacity: 0.6;
    cursor: not-allowed;
}

.loader {
    border: 4px solid #3d3d3d;
    border-top: 4px solid #bb86fc;
    border-radius: 50%;
    width: 40px;
    height: 40px;
    animation: spin 1s linear infinite;
    margin: 20px auto;
}

@keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
}

.hidden {
    display: none;
}

.error {
    background: #cf6679;
    color: #000;
    padding: 12px;
    border-radius: 8px;
    margin: 20px 0;
    text-align: center;
}

.result {
    margin-top: 30px;
    text-align: center;
}

#thumbnail {
    max-width: 100%;
    max-height: 300px;
    border-radius: 8px;
    margin-bottom: 15px;
    border: 2px solid #555;
}

#filename {
    margin-bottom: 5px;
    color: #fff;
    word-break: break-word;
}

#fileSize {
    margin-bottom: 20px;
}

.download-buttons {
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
    justify-content: center;
}

.download-btn {
    display: inline-block;
    padding: 10px 20px;
    background: #03dac6;
    color: #000;
    text-decoration: none;
    border-radius: 6px;
    font-weight: 500;
    transition: background 0.2s;
}

.download-btn:hover {
    background: #02b3a0;
}

.social-links {
    margin-top: 40px;
    display: flex;
    justify-content: center;
    gap: 20px;
}

.social-links a {
    color: #bb86fc;
    text-decoration: none;
    font-size: 14px;
}

.social-links a:hover {
    text-decoration: underline;
}
EOF

# Create public/script.js
cat > public/script.js << 'EOF'
const urlInput = document.getElementById('urlInput');
const submitBtn = document.getElementById('submitBtn');
const loader = document.getElementById('loader');
const errorDiv = document.getElementById('error');
const resultDiv = document.getElementById('result');
const thumbnailImg = document.getElementById('thumbnail');
const filenameEl = document.getElementById('filename');
const fileSizeEl = document.getElementById('fileSize');
const downloadButtonsDiv = document.getElementById('downloadButtons');

submitBtn.addEventListener('click', async () => {
    const url = urlInput.value.trim();
    if (!url) {
        showError('Please enter a URL');
        return;
    }

    hideError();
    resultDiv.classList.add('hidden');
    loader.classList.remove('hidden');
    submitBtn.disabled = true;

    try {
        const response = await fetch('/api/resolve', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ url })
        });

        const data = await response.json();

        if (!response.ok || data.status === 'error') {
            throw new Error(data.message || 'Request failed');
        }

        displayResult(data);
    } catch (err) {
        showError(err.message);
    } finally {
        loader.classList.add('hidden');
        submitBtn.disabled = false;
    }
});

function displayResult(data) {
    if (data.thumbnail) {
        thumbnailImg.src = data.thumbnail;
        thumbnailImg.alt = data.filename;
    } else {
        thumbnailImg.src = '';
        thumbnailImg.alt = 'No thumbnail';
    }

    filenameEl.textContent = data.filename || 'Unknown file';
    
    if (data.size) {
        fileSizeEl.textContent = `Size: ${data.size}`;
    } else {
        fileSizeEl.textContent = '';
    }

    downloadButtonsDiv.innerHTML = '';
    const urls = [data.url1, data.url2, data.url3].filter(url => url && url.trim() !== '');
    
    if (urls.length > 0) {
        urls.forEach((url, index) => {
            const btn = document.createElement('a');
            btn.href = url;
            btn.target = '_blank';
            btn.rel = 'noopener noreferrer';
            btn.className = 'download-btn';
            btn.textContent = `Download ${urls.length > 1 ? `Option ${index + 1}` : ''}`.trim();
            downloadButtonsDiv.appendChild(btn);
        });
    } else {
        downloadButtonsDiv.innerHTML = '<p style="color:#aaa;">No download links found</p>';
    }

    resultDiv.classList.remove('hidden');
}

function showError(msg) {
    errorDiv.textContent = msg;
    errorDiv.classList.remove('hidden');
}

function hideError() {
    errorDiv.classList.add('hidden');
}
EOF

echo "All files created successfully!"
