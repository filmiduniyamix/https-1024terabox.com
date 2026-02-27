const express = require('express');
const { resolveUrl } = require('../controllers/resolveController');
const router = express.Router();

router.post('/resolve', resolveUrl);

module.exports = router;
