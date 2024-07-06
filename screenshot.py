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

def configure_driver():
    chrome_options = Options()
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--window-size=414,896")
    chrome_options.add_argument("--lang=en-US")
    return webdriver.Chrome(service=ChromeService(ChromeDriverManager().install()), options=chrome_options)

def inject_styles(driver):
    driver.execute_script("document.documentElement.style.setProperty('--bg-page', '#ffffff');")
    font_injection_script = """
        var font = new FontFace('Roboto', 'url(https://fonts.gstatic.com/s/roboto/v27/KFOmCnqEu92Fr1Mu4mxP.ttf)');
        document.fonts.add(font);
        document.body.style.fontFamily = 'Roboto, sans-serif';
    """
    driver.execute_script(font_injection_script)

def capture_element_screenshot(driver, element, save_path, color, align, font_family, font_size):
    driver.execute_script(f"""
        arguments[0].style.color = '{color}';
        arguments[0].style.textAlign = '{align}';
        arguments[0].style.fontFamily = '{font_family}';
        arguments[0].style.fontSize = '{font_size}';
    """, element)
    time.sleep(1)
    image_binary = element.screenshot_as_png
    img = Image.open(io.BytesIO(image_binary))
    bordered_img = add_border(add_border(img, border_size=6, color='#FFFFFF'))
    bordered_img.save(save_path)

def capture_screenshots(url, class_name, button_tag_name):
    driver = configure_driver()
    max_non_overlayed_element_height = 600
    bottom_menu_height = 70
    button_width = 30

    try:
        driver.get(url)
        inject_styles(driver)
        time.sleep(1)
        
        WebDriverWait(driver, 10).until(
            EC.presence_of_all_elements_located((By.CLASS_NAME, class_name))
        )

        h1_element = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.TAG_NAME, 'h1'))
        )
        capture_element_screenshot(driver, h1_element, "header.png", '#0375B8', 'center', 'Roboto, sans-serif', '45px')

        elements = driver.find_elements(By.CLASS_NAME, class_name)

        if elements and len(elements) > 1:
            button = elements[1].find_element(By.TAG_NAME, button_tag_name)
            button.click()
            time.sleep(2)
            
            last_div = elements[1].find_elements(By.TAG_NAME, "div")[-1]
            driver.execute_script("""
                var first_italic = arguments[0].querySelector('i');
                if (first_italic) {
                    first_italic.parentNode.removeChild(first_italic);
                }
            """, last_div)
            driver.execute_script("arguments[0].scrollIntoView(true);", last_div)
            time.sleep(1)
            capture_element_screenshot(driver, last_div, "answer.png", '#0375B8', 'left', 'Roboto, sans-serif', '24px')
            button.click()
            time.sleep(2)
        
        for index, element in enumerate(elements):
            for button in element.find_elements(By.TAG_NAME, button_tag_name):
                driver.execute_script("arguments[0].remove()", button)

            capture_element_screenshot(driver, element, f"question_{index + 1}.png", '#0375B8', 'left', 'Roboto, sans-serif', '24px')

    finally:
        driver.quit()

# Example usage
url = 'https://app.slonig.org/#/knowledge?id=0xde25f95b5ed1e15318f1dadcf5b64c3e6f4b33d685f81247b490ad4efb206343'
class_name = 'exercise-display'
button_tag_name = 'button'

capture_screenshots(url, class_name, button_tag_name)