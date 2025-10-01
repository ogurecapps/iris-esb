FROM intersystems/iris-community:latest-cd

USER root
WORKDIR /opt/esb

RUN chown ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /opt/esb
COPY deployment/ .
RUN chmod +x ./irissession.sh

USER ${ISC_PACKAGE_MGRUSER}

COPY src src

SHELL ["./irissession.sh"]

RUN \
  do $SYSTEM.OBJ.Load("./Installer.cls", "ck") \
  set sc = ##class(App.Installer).Setup()

# bringing the standard shell back
SHELL ["/bin/bash", "-c"]