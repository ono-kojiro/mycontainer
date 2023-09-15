FROM jammy

#
# Sphinx
#
RUN    DEBIAN_FRONTEND=noninteractive apt-get -qq update \
    && DEBIAN_FRONTEND=noninteractive apt-get -qq install \
      texlive-lang-japanese \
      texlive-latex-recommended \
      texlive-latex-extra \
      tex-gyre \
      latexmk \
      python3-sphinx \
      python3-sphinx-rtd-theme \
    && apt-get -qq clean \
    && rm -rf /var/lib/apt/lists/*

