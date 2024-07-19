import asyncio
import sys
from playwright.async_api import async_playwright


async def main():
    args = sys.argv[1:]
    if len(args) != 1:
        print("Usage: python setup_youtrack.py <wizard_token>")
        sys.exit(1)

    WIZARD_TOKEN = args[0]

    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=False)
        page = await browser.new_page()
        await page.goto("https://www.google.com")
        print(await page.title())
        await browser.close()
        await page.goto("http://localhost:8080")
        await page.get_by_role("textbox").fill(WIZARD_TOKEN)
        await page.get_by_role("button", name="Log in").click()
        await page.get_by_role("link", name="Set up").click()
        await page.get_by_role("button", name="Next").click()
        await page.locator("input[name='adminLogin']").click()
        await page.locator("input[name='adminLogin']").fill("admin")
        await page.locator("input[name='password']").click()
        await page.keyboard.type("admin")
        await page.locator("input[name='confirmPassword']").click()
        await page.keyboard.type("admin")
        await page.get_by_role("button", name="Next").click()
        await page.get_by_role("button", name="Finish").click()
        await page.get_by_role("textbox", name="Username or Email").fill("admin")
        await page.get_by_role("textbox", name="password").fill("admin")
        await page.get_by_role("button", name="Log in").click()
        await page.get_by_text("Explore the demo project").click()
        await page.goto("http://localhost:8080/admin/hub/users")
        await page.locator("[data-test='ring-table-body']").get_by_role(
            "link", name="admin"
        ).click()
        await page.get_by_role("tab", name="Account Security").click()
        await page.locator("[data-test='new-token']").click()
        await page.locator("[data-test='ring-dialog']").get_by_label("Name").fill(
            "automation"
        )
        await page.locator("[data-test='ring-dialog']").get_by_label("Name").press(
            "Enter"
        )
        token = await page.locator(
            "[class='user-page__authentication__show-token__value']"
        ).inner_text()
        with open("youtrack_token.txt", "w") as f:
            f.write(token)
        await browser.close()


if __name__ == "__main__":
    asyncio.run(main())
