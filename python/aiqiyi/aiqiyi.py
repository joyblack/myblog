import os
from selenium import webdriver
# 浏览器设置
option = webdriver.ChromeOptions()
option.add_argument("headless")
driver = webdriver.Chrome(options=option)
# 首页地址
url = "https://list.iqiyi.com/www/1/-------------24-[page]-1-iqiyi--.html"
# 总页数
page = 1
# 获取所有电影
nowPage = 1
while nowPage <= page:
    nowUrl = url.replace("[page]", str(nowPage))
    driver.get(nowUrl)
    #html_source = driver.page_source
    moveList = driver.find_element_by_class_name("wrapper-piclist")
    
    print(format(moveList))
    imgs = moveList.find_elements_by_tag_name("img")
    for img in imgs:
        print(img.parent)
        print(img.get_attribute("src"))
    # htmlFile = open('sampleList.sunrun', 'w', encoding='utf-8')
    # htmlFile.write(html_source)
    nowPage = nowPage + 1
