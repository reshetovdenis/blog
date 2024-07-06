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

def capture_screenshots(url, class_name, button_tag_name):
    # Configure Selenium to use Chrome
    chrome_options = Options()
    chrome_options.add_argument("--headless")  # Run in headless mode for no GUI
    chrome_options.add_argument("--window-size=414,896")
    chrome_options.add_argument("--lang=en-US")
    driver = webdriver.Chrome(service=ChromeService(ChromeDriverManager().install()), options=chrome_options)
    max_non_overlayed_element_height = 600
    bottom_menu_height = 70
    button_width = 30

    try:
        # Open the webpage
        driver.get(url)
        
        # Wait until the elements are present
        WebDriverWait(driver, 10).until(
            EC.presence_of_all_elements_located((By.CLASS_NAME, class_name))
        )

        # Find all elements with the given class name
        elements = driver.find_elements(By.CLASS_NAME, class_name)

        if elements:
            for index, element in enumerate(elements):
                # Capture screenshot of each element
                image_binary = element.screenshot_as_png 
                img = Image.open(io.BytesIO(image_binary))
                
                width, height = img.size
                if height > max_non_overlayed_element_height:
                    height = height - bottom_menu_height
                cropped_img = img.crop((0, 0, width, height))
                cropped_img.save(f"question_{index + 1}.png")

            if len(elements) > 1:
                # Click the button inside the second element
                button = elements[1].find_element(By.TAG_NAME, button_tag_name)
                button.click()

                # Re-capture screenshot of the second element after clicking the button
                time.sleep(2)  # Wait for any changes to take effect after the click
                divs = elements[1].find_elements(By.TAG_NAME, "div")
                last_div = divs[-1]  # Get the last div
                
                # Scroll the last div to the top of the page
                driver.execute_script("arguments[0].scrollIntoView(true);", last_div)
                time.sleep(1)  # Wait for the scroll to complete

                # Capture screenshot of the last div
                image_binary = last_div.screenshot_as_png 
                img = Image.open(io.BytesIO(image_binary))
                
                width, height = img.size
                if height > max_non_overlayed_element_height:
                    height = height - bottom_menu_height
                cropped_img = img.crop((button_width, 0, width, height))
                
                cropped_img.save("answer.png")
        else:
            print("No elements found with the specified class name.")

    finally:
        driver.quit()

# Example usage
url = 'https://app.slonig.org/#/knowledge?id=0xd86f01db4b3157dd34268122e6ba45895632e2406b8011c54982024b2180a550'
#url = 'https://app.slonig.org/#/knowledge?id=0x10bddf453ccd8118d85521ac958e6fd8ff133d688f326d4ff36e301a638c28fe'

class_name = 'exercise-display'
button_tag_name = 'button'  # Update this with the correct tag name for the button if it's not 'button'

capture_screenshots(url, class_name, button_tag_name)