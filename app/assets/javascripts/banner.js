const banners = [
    '<img src="banner1.jpg" alt="Banner 1">',
    '<img src="banner2.jpg" alt="Banner 2">',
    '<img src="banner3.jpg" alt="Banner 3">',
    '<img src="banner4.jpg" alt="Banner 4">'
];

const assert = require('assert');

function getRandomBanner(banners) {
    const randomIndex = Math.floor(Math.random() * banners.length);
    return banners[randomIndex];
}

function rotateBanners(banners) {
    banners.push(banners.shift());
}

function getDisplayedBanner(banners) {
    return banners[0];
}

describe('Banner Rotation Tests', function() {
    it('should display the first banner after four rotations', function() {
        const banners = ['Banner1', 'Banner2', 'Banner3', 'Banner4'];
        rotateBanners(banners);
        rotateBanners(banners);
        rotateBanners(banners);
        rotateBanners(banners);
        const displayedBanner = getDisplayedBanner(banners);
        assert.strictEqual(displayedBanner, 'Banner1'); // Added assertion to check the expected outcome
    });
});