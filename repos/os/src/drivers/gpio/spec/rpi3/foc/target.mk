TARGET   = foc_gpio_drv
REQUIRES = rpi3
SRC_CC  += main.cc
LIBS     = base
INC_DIR += $(PRG_DIR) $(PRG_DIR)/..

vpath main.cc $(PRG_DIR)/..
