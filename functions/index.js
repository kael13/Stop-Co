const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { initializeApp } = require('firebase-admin/app');
const { defineSecret } = require('firebase-functions/params');

initializeApp();

const tomtomApiKey = defineSecret('TOMTOM_API_KEY');
const TOMTOM_BASE_URL = 'https://api.tomtom.com';

exports.tomtomSearch = onCall(
  { secrets: [tomtomApiKey] },
  async (request) => {
    const { query, nearLat, nearLon, countrySet, limit } = request.data;

    let url = `${TOMTOM_BASE_URL}/search/2/search/${encodeURIComponent(query)}.json`
      + `?key=${tomtomApiKey.value()}&limit=${limit || 5}`;

    if (nearLat != null && nearLon != null) {
      url += `&lat=${nearLat}&lon=${nearLon}`;
      if (countrySet) url += `&countrySet=${countrySet}`;
    }

    const response = await fetch(url, {
      headers: { 'User-Agent': 'StopCo/1.0' },
    });

    if (!response.ok) {
      throw new HttpsError('internal', `TomTom search failed: ${response.status}`);
    }

    return response.json();
  }
);

exports.tomtomReverseGeocode = onCall(
  { secrets: [tomtomApiKey] },
  async (request) => {
    const { lat, lon } = request.data;

    const url = `${TOMTOM_BASE_URL}/search/2/reverseGeocode/${lat},${lon}.json`
      + `?key=${tomtomApiKey.value()}`;

    const response = await fetch(url, {
      headers: { 'User-Agent': 'StopCo/1.0' },
    });

    if (!response.ok) {
      throw new HttpsError('internal', `TomTom reverse geocode failed: ${response.status}`);
    }

    return response.json();
  }
);
