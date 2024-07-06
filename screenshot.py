from selenium import webdriver
from selenium.webdriver.chrome.service import Service as ChromeService
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from PIL import Image
import io
import time

def capture_screenshots(url, class_name):
    # Configure Selenium to use Chrome
    chrome_options = Options()
    chrome_options.add_argument("--headless")  # Run in headless mode for no GUI
    chrome_options.add_argument("--window-size=414,896")
    driver = webdriver.Chrome(service=ChromeService(ChromeDriverManager().install()), options=chrome_options)

    try:
        # Open the webpage
        driver.get(url)
        
        # Wait until the element is present
        element = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.CLASS_NAME, class_name))
        )
        #time.sleep(2)  # Ensure the page is fully loaded
 
        image_binary = element.screenshot_as_png 
        img = Image.open(io.BytesIO(image_binary))
        img.save("image.png")

    finally:
        driver.quit()

# Example usage
# url = 'https://app.slonig.org/#/knowledge?id=0xd86f01db4b3157dd34268122e6ba45895632e2406b8011c54982024b2180a550'
url = 'https://app.slonig.org/#/knowledge?id=0x10bddf453ccd8118d85521ac958e6fd8ff133d688f326d4ff36e301a638c28fe'

class_name = 'exercise-display'

capture_screenshots(url, class_name)
