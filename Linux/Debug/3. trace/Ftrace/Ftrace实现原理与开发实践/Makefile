# Author: Wu Zhangjin / Falcon <wuzhangjin@gmail.com>
# Update: 2014/01/17 PM 14:20

SRC = $(wildcard *.md)

html_theme=dzslides
latex_theme=Darmstadt

# colortheme: beaver,crane,dolphin,dove,fly,lily
# monarca,seagull,seahorse,spruce,wolverine
latex_colortheme=seahorse

# Put and select the .jpg's in images/, without suffix
# e.g. earth, white, darkgray; mx6, orange, black
titlepage_wallpaper=linux-desktop
titlepage_titlefg=yellow
titlepage_authorfg=white

# toc bg/fg
toc_number_bg=white
toc_number_fg=violet
toc_section_bg=white
toc_section_fg=blue

latex_fontsize=9pt
latex_template=./templates/zh_template.tex

PDFS=$(SRC:.md=.pdf)
HTML=$(SRC:.md=.html)
IMGS=$(wildcard images/*.jpg)

all: clean $(PDFS) $(HTML)

pdf: $(PDFS)

html: $(HTML)

%.pdf: %.md $(latex_template) $(IMGS)
	@#sed -n ':a;1,5!{P;N;D;};N;ba' $< > tmp-$<
	sed '/^# 致谢/,$$d' $< > $<.tmp
	pandoc -t beamer --toc \
	  --latex-engine=xelatex \
	  --template=$(latex_template) \
	  -V titlepage_wallpaper:$(titlepage_wallpaper) \
	  -V titlepage_titlefg:$(titlepage_titlefg) \
	  -V titlepage_authorfg:$(titlepage_authorfg) \
	  -V toc_number_bg:$(toc_number_bg) \
	  -V toc_number_fg:$(toc_number_fg) \
	  -V toc_section_bg:$(toc_section_bg) \
	  -V toc_section_fg:$(toc_section_fg) \
	  -V colortheme:$(latex_colortheme) \
	  -V theme:$(latex_theme) \
	  -V fontsize:$(latex_fontsize) \
	  $<.tmp -o $@
	rm $<.tmp

%.html: %.md
	pandoc -t $(html_theme) -s --mathjax $< -o $@

read: $(PDFS)
	chromium-browser $^ 2>&1 >/dev/null &

read-html: $(HTML)
	chromium-browser $^ 2>&1 >/dev/null &

clean:
	rm -rf *.pdf *.html
