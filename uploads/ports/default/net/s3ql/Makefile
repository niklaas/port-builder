# $FreeBSD$

PORTNAME=		s3ql
PORTVERSION=	2.21
CATEGORIES=		net
MASTER_SITES=	https://bitbucket.org/nikratio/s3ql/downloads/

MAINTAINER=	stdin@niklaas.eu
COMMENT=	File system that stores all its data in the cloud

LICENSE=		GPLv3
LICENSE_FILE=	${WRKSRC}/LICENSE

MY_DEPENDS=		${PYTHON_PKGNAMEPREFIX}apsw>=3.7:databases/py-apsw \
				${PYTHON_PKGNAMEPREFIX}defusedxml>=0:devel/py-defusedxml \
				${PYTHON_PKGNAMEPREFIX}requests>=0:www/py-requests \
				${PYTHON_PKGNAMEPREFIX}pycrypto>=0:security/py-pycrypto \
				${PYTHON_PKGNAMEPREFIX}llfuse>=0:devel/py-llfuse \
				${PYTHON_PKGNAMEPREFIX}dugong>=0:net/py-dugong \
				psmisc>=0:sysutils/psmisc \
				ca_root_nss>=0:security/ca_root_nss
BUILD_DEPENDS=	${MY_DEPENDS}
RUN_DEPENDS=	${MY_DEPENDS}

CPPFLAGS+=-I${LOCALBASE}/include
LDFLAGS+=-L${LOCALBASE}/lib

USES=		python:3.3+ tar:bz2 sqlite
USE_PYTHON=	autoplist distutils

post-install:
	${STRIP_CMD} ${STAGEDIR}${PYTHONPREFIX_SITELIBDIR}/s3ql/deltadump.so

.include <bsd.port.pre.mk>

.if ${PYTHON_MAJOR_VER} == 3
NO_PACKAGE=Requires python 3.x to be set as default
.endif

.include <bsd.port.post.mk>
