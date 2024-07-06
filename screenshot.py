from selenium import webdriver
from selenium.webdriver.chrome.service import Service as ChromeService
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from PIL import Image, ImageOps
import io
import time

def add_border(image, border_size=6, color='#F59C04'):
    return ImageOps.expand(image, border=border_size, fill=color)

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

        driver.execute_script("document.documentElement.style.setProperty('--bg-page', '#ffffff');")

        # Inject Futura Medium font into the page
        font_injection_script = """
            var font = new FontFace('FuturaMedium', 'url(https://fonts.cdnfonts.com/s/13918/FuturaLT-Book.woff)');
            document.fonts.add(font);
            document.body.style.fontFamily = 'FuturaMedium, Arial, sans-serif';
        """
        driver.execute_script(font_injection_script)
        time.sleep(1)
        
        # Wait until the elements are present
        WebDriverWait(driver, 10).until(
            EC.presence_of_all_elements_located((By.CLASS_NAME, class_name))
        )

        # Capture screenshot of the first h1 element
        h1_element = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.TAG_NAME, 'h1'))
        )
        driver.execute_script("""
            arguments[0].style.color = '#0375B8';
            arguments[0].style.textAlign = 'center';
            arguments[0].style.fontFamily = 'FuturaMedium, Arial, sans-serif';
            arguments[0].style.fontSize = '45px';
        """, h1_element)

        time.sleep(1)
        h1_image_binary = h1_element.screenshot_as_png
        h1_img = Image.open(io.BytesIO(h1_image_binary))
        h1_bordered_img = add_border(add_border(h1_img, border_size=6, color='#FFFFFF'))
        h1_bordered_img.save("header.png")

        # Find all elements with the given class name
        elements = driver.find_elements(By.CLASS_NAME, class_name)

        if elements:
            if len(elements) > 1:
                # Click the button inside the second element
                button = elements[1].find_element(By.TAG_NAME, button_tag_name)
                button.click()

                # Re-capture screenshot of the second element after clicking the button
                time.sleep(2)  # Wait for any changes to take effect after the click
                divs = elements[1].find_elements(By.TAG_NAME, "div")
                last_div = divs[-1]  # Get the last div

                driver.execute_script("""
                    arguments[0].style.color = '#0375B8';
                    arguments[0].style.textAlign = 'left';
                    arguments[0].style.fontFamily = 'FuturaMedium, Arial, sans-serif';
                    arguments[0].style.fontSize = '24px';
                """, last_div)
                
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
                
                # Add border to the image
                bordered_img = add_border(add_border(cropped_img, border_size=6, color='#FFFFFF'))
                bordered_img.save("answer.png")
                button.click()
                time.sleep(2)
            
            for index, element in enumerate(elements):
                buttons = element.find_elements(By.TAG_NAME, button_tag_name)
                for button in buttons:
                    driver.execute_script("arguments[0].remove()", button)

                driver.execute_script("""
                    arguments[0].style.color = '#0375B8';
                    arguments[0].style.textAlign = 'left';
                    arguments[0].style.fontFamily = 'FuturaMedium, Arial, sans-serif';
                    arguments[0].style.fontSize = '24px';
                """, element)

                time.sleep(1)
                # Capture screenshot of each element
                image_binary = element.screenshot_as_png 
                img = Image.open(io.BytesIO(image_binary))
                
                width, height = img.size
                if height > max_non_overlayed_element_height:
                    height = height - bottom_menu_height
                cropped_img = img.crop((0, 0, width, height))
                
                # Add border to the image
                bordered_img = add_border(add_border(cropped_img, border_size=6, color='#FFFFFF'))
                
                bordered_img.save(f"question_{index + 1}.png")
        else:
            print("No elements found with the specified class name.")

    finally:
        driver.quit()

# Example usage
url = 'https://app.slonig.org/#/knowledge?id=0xde25f95b5ed1e15318f1dadcf5b64c3e6f4b33d685f81247b490ad4efb206343'
#url = 'https://app.slonig.org/#/knowledge?id=0xd86f01db4b3157dd34268122e6ba45895632e2406b8011c54982024b2180a550'
#url = 'https://app.slonig.org/#/knowledge?id=0x10bddf453ccd8118d85521ac958e6fd8ff133d688f326d4ff36e301a638c28fe'

class_name = 'exercise-display'
button_tag_name = 'button'  # Update this with the correct tag name for the button if it's not 'button'

capture_screenshots(url, class_name, button_tag_name)