# FROM –   BASE IMAGE FROM REPOSITORY
# WORKDIR – container 工作目錄
# COPY– 將本地端資料複製到container裡
# EXPOSE – open container port
# Run  --  build image  中執行的 cmd
# CMD –  build container 執行cmd


FROM centos:7

USER root

# Install dev tools.
RUN yum update -y && yum clean all

# Install specific libs requires for Python to build
RUN yum install -y gcc gcc++ kernel-devel make
RUN yum install -y zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gdbm-devel db4-devel libpcap-devel xz-devel
RUN yum install -y libxml2-devel libxml++-devel python-devel

# Download Python 3 and compile
RUN cd /opt \
    && curl -O https://www.python.org/ftp/python/3.6.0/Python-3.6.0.tar.xz \
    && tar xf Python-3.6.0.tar.xz && cd Python-3.6.0 \
    &&./configure --prefix=/usr/local --enable-shared LDFLAGS="-Wl,-rpath /usr/local/lib" \
    && make \
    && make altinstall && cd /opt \
    && rm -f Python-3.6.0.tar.xz \
    && rm -rf Python-3.6.0/

# Install useful python tools
RUN yum install -y python-dateutil

# Install Teradata Drivers
RUN yum -y install ksh
COPY ./tdodbc1510__linux_indep.15.10.01.05-1.tar /code/
COPY ./install_teradata_drivers.sh /code/
RUN bash /code/install_teradata_drivers.sh
# Add path to Teradata Drivers.
ENV ODBCINI /app/vendored/teradata/client/ODBC_64/odbc.ini
ENV ODBCINST /app/vendored/teradata/client/ODBC_64/odbcinst.ini

# Install Pip
RUN curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"
RUN python get-pip.py

# Install Main Requirements
COPY ./requirements.txt /code/
RUN pip install -r /code/requirements.txt

# Configure environment
ENV SHELL /bin/bash
ENV TD_USER tduser
ENV TD_UID 1000
ENV HOME /home/$TD_USER

# Create user with UID=1000 and in the 'users' group
RUN useradd -m -s /bin/bash -N -u $TD_UID $TD_USER

# Setup user home directory
RUN mkdir /home/$TD_USER/.local
WORKDIR /home/$TD_USER/work
