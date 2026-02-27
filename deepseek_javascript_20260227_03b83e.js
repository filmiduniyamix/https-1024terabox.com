const axios = require('axios');
const { logger } = require('../utils/logger');

const resolveUrl = async (req, res, next) => {
  const startTime = Date.now();
  try {
    const { url } = req.body;
    if (!url || !url.includes('1024terabox.com')) {
      return res.status(400).json({ status: 'error', message: 'Invalid 1024terabox URL' });
    }

    // External API endpoint
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