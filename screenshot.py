from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service as ChromeService
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager
from PIL import Image
import time

# Setup the Chrome driver
driver = webdriver.Chrome(service=ChromeService(ChromeDriverManager().install()))

# Open the webpage
url = 'https://everymac.com/systems/apple/macbook_pro/specs/macbook-pro-core-i5-3.3-13-mid-2017-retina-display-touch-bar-specs.html'
driver.get(url)

# Wait for the element to be visible
wait = WebDriverWait(driver, 10)
element = wait.until(EC.visibility_of_element_located((By.CLASS_NAME, 'specstop')))

# Scroll the element into view using JavaScript
driver.execute_script("arguments[0].scrollIntoView(true);", element)

# Additional wait to ensure scrolling is complete
time.sleep(2)

# Get the element location and size after scrolling into view
location = element.location_once_scrolled_into_view
size = element.size

# Take screenshot of the entire page
screenshot_path = 'full_screenshot.png'
driver.save_screenshot(screenshot_path)

# Open the image and crop to the element
image = Image.open(screenshot_path)
left = location['x']
top = location['y']
right = left + size['width']
bottom = top + size['height']

image = image.crop((left, top, right, bottom))
element_screenshot_path = 'element_screenshot.png'
image.save(element_screenshot_path)

# Close the browser
driver.quit()

print(f'Screenshot saved to {element_screenshot_path}')
