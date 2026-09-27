"""Check a deployed (or local) copy of the site in a headless browser.

For each project page: the player mounts, starts playing when clicked, and its
current time moves forward. On the image page: every gallery image for every
sample finishes loading with a non-zero size. On the video pages: the video
plays and every screenshot loads.

usage: uv run --with playwright --python 3.12 python recording/verify.py BASE_URL [SCREENSHOT_DIR]
"""
import sys
import time

from playwright.sync_api import sync_playwright

BASE = sys.argv[1].rstrip("/")
SHOTS = sys.argv[2] if len(sys.argv) > 2 else None
PAGES = ["/raft/", "/robot-factory/", "/image-processing/", "/meditrack/", "/data-structures/",
         "/taskmaster/", "/taskmanager-swift/"]

# Pages with a video: minimum duration (s), expected width, number of screenshots.
VIDEOS = {
    "/meditrack/": (60, 1280, 10),
    "/taskmaster/": (150, 540, 10),
    "/taskmanager-swift/": (40, 1280, 10),
}

failures = []


def check(cond, msg):
    print(("ok   " if cond else "FAIL ") + msg)
    if not cond:
        failures.append(msg)


with sync_playwright() as p:
    browser = p.chromium.launch()
    page = browser.new_page(viewport={"width": 1280, "height": 900})
    errors = []
    page.on("pageerror", lambda e: errors.append(str(e)))
    page.on("console", lambda m: m.type == "error" and errors.append(m.text))

    resp = page.goto(BASE + "/")
    check(resp.status == 200, f"/ returns {resp.status}")

    for path in PAGES:
        resp = page.goto(BASE + path)
        check(resp.status == 200, f"{path} returns {resp.status}")
        page.wait_for_selector(".ap-player", timeout=15000)
        check(page.locator(".cmds").count() == 1, f"{path} has a command listing")
        page.locator(".ap-player").first.click()
        t0 = page.evaluate("document.querySelector('.player').player.getCurrentTime()")
        time.sleep(4)
        t1 = page.evaluate("document.querySelector('.player').player.getCurrentTime()")
        dur = page.evaluate("document.querySelector('.player').player.getDuration()")
        text = page.locator(".ap-term").first.inner_text()
        check(t1 > t0 + 1, f"{path} player advances ({t0:.1f}s -> {t1:.1f}s of {dur:.1f}s)")
        check(len(text.strip()) > 0, f"{path} terminal shows text ({text.strip().splitlines()[0][:60]!r})")
        if SHOTS:
            page.screenshot(path=f"{SHOTS}/{path.strip('/') or 'index'}.png", full_page=False)

        if path == "/image-processing/":
            buttons = page.locator(".gallery-controls button")
            n = buttons.count()
            check(n == 4, f"gallery has {n} sample images")
            for i in range(n):
                buttons.nth(i).click()
                page.wait_for_timeout(300)
                imgs = page.locator("#gallery .grid img")
                count = imgs.count()
                for j in range(count):
                    imgs.nth(j).scroll_into_view_if_needed()
                page.wait_for_function(
                    "() => [...document.querySelectorAll('#gallery .grid img')].every(i => i.complete)",
                    timeout=30000)
                broken = page.evaluate(
                    "() => [...document.querySelectorAll('#gallery .grid img')]"
                    ".filter(i => !(i.naturalWidth > 0)).map(i => i.src)")
                check(count == 28 and not broken,
                      f"gallery '{buttons.nth(i).inner_text()}': {count} images, {len(broken)} broken")
            if SHOTS:
                page.locator("#gallery").screenshot(path=f"{SHOTS}/gallery.png")

        if path in VIDEOS:
            min_d, width, n_shots = VIDEOS[path]
            video = page.locator("video").first
            video.scroll_into_view_if_needed()
            page.evaluate("document.querySelector('video').muted = true; document.querySelector('video').play()")
            page.wait_for_function("document.querySelector('video').readyState >= 2", timeout=30000)
            time.sleep(2)
            v = page.evaluate("(() => { const v = document.querySelector('video');"
                              " return {t: v.currentTime, d: v.duration, w: v.videoWidth, h: v.videoHeight, err: v.error && v.error.code}; })()")
            check(not v["err"] and v["d"] > min_d and v["w"] == width and v["t"] > 0.5,
                  f"{path} video loads and plays ({v['w']}x{v['h']}, {v['d']:.1f}s, at {v['t']:.1f}s)")
            shots = page.locator(".shots img")
            for j in range(shots.count()):
                shots.nth(j).scroll_into_view_if_needed()
            page.wait_for_function("[...document.querySelectorAll('.shots img')].every(i => i.complete)", timeout=30000)
            broken = page.evaluate("[...document.querySelectorAll('.shots img')].filter(i => !(i.naturalWidth > 0)).length")
            check(shots.count() == n_shots and broken == 0, f"{path} screenshots: {shots.count()} images, {broken} broken")
            links = page.evaluate("[...document.querySelectorAll('a.download')].map(a => a.href)")
            if path != "/meditrack/":
                check(len(links) == 1, f"{path} has a download link ({links[:1]})")

    check(not errors, f"no page errors ({errors[:3]})")
    browser.close()

print(f"\n{len(failures)} failure(s)")
sys.exit(1 if failures else 0)
