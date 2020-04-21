ifndef COMPILER
$(error COMPILER is not set)
endif

AVX=1
OPENMP=1
DEBUG=0

VPATH=./src/
EXEC=darknet.$(COMPILER)
OBJDIR=./obj/

LDFLAGS= -lm -pthread
COMMON= -Iinclude/ -I3rdparty/stb/include
CFLAGS=-Wall

ifeq ($(COMPILER), gcc)
	CC=gcc
	CPP=g++
	CFLAGS+=-Wextra -Wno-unused-variable -Wno-unused-parameter -Wno-unused-but-set-variable -Wno-sign-compare -Wno-unknown-pragmas -Wno-missing-field-initializers -Wno-switch -Wno-unused-function -Wno-implicit-fallthrough -Wno-type-limits -Wno-unused-value -Wno-format-overflow

	ifeq ($(OPENMP), 1)
		CFLAGS+= -fopenmp -DOPENMP
		LDFLAGS+= -lgomp -DOPENMP
	endif	

	ifeq ($(AVX), 1)
		CFLAGS+=-ffp-contract=fast -mavx -mavx2 -msse3 -msse4.1 -msse4.2 -msse4a
	endif
endif

ifeq ($(COMPILER), icc)
	CC=icc
	CPP=icpc
	CFLAGS+=-Wextra

	ifeq ($(OPENMP), 1)
		CFLAGS+=-qopenmp -DOPENMP
	endif

	# https://cvw.cac.cornell.edu/vector/compilers_enabling
	# https://software.intel.com/en-us/articles/performance-tools-for-software-developers-intel-compiler-options-for-sse-generation-and-processor-specific-optimizations
	ifeq ($(AVX), 1)
 		CFLAGS+=-ipo -xCORE-AVX512 -qopt-zmm-usage=high -qopt-report=4 -qopt-report-phase ipo
	endif
endif

ifeq ($(COMPILER), ncc)
	CC=/opt/nec/ve/bin/ncc
	CPP=/opt/nec/ve/bin/nc++
	CFLAGS+=

	ifeq ($(OPENMP), 1)
		CFLAGS+=-fopenmp -DOPENMP
	endif	

	ifeq ($(AVX), 1)
		AVX=0
		CFLAGS+=-mvector
	endif
endif

ifeq ($(DEBUG), 1)
COMMON+=-DDEBUG
CFLAGS+=-DDEBUG
endif


OBJ=image_opencv.o http_stream.o gemm.o utils.o dark_cuda.o convolutional_layer.o list.o image.o activations.o im2col.o col2im.o blas.o crop_layer.o dropout_layer.o maxpool_layer.o softmax_layer.o data.o matrix.o network.o connected_layer.o cost_layer.o parser.o option_list.o darknet.o detection_layer.o captcha.o route_layer.o writing.o box.o nightmare.o normalization_layer.o avgpool_layer.o coco.o dice.o yolo.o detector.o layer.o compare.o classifier.o local_layer.o swag.o shortcut_layer.o activation_layer.o rnn_layer.o gru_layer.o rnn.o rnn_vid.o crnn_layer.o demo.o tag.o cifar.o go.o batchnorm_layer.o art.o region_layer.o reorg_layer.o reorg_old_layer.o super.o voxel.o tree.o yolo_layer.o gaussian_yolo_layer.o upsample_layer.o lstm_layer.o conv_lstm_layer.o scale_channels_layer.o sam_layer.o

OBJS = $(addprefix $(OBJDIR), $(OBJ))
DEPS = $(wildcard src/*.h) Makefile include/darknet.h

all: $(OBJDIR) backup results setchmod $(EXEC)

$(EXEC): $(OBJS)
	$(CPP) -std=c++11 $(COMMON) $(CFLAGS) $^ -o $@ $(LDFLAGS)

$(OBJDIR)%.o: %.c $(DEPS)
	$(CC) $(COMMON) $(CFLAGS) -c $< -o $@

$(OBJDIR)%.o: %.cpp $(DEPS)
	$(CPP) -std=c++11 $(COMMON) $(CFLAGS) -c $< -o $@

$(OBJDIR):
	mkdir -p $(OBJDIR)

backup:
	mkdir -p backup

results:
	mkdir -p results

setchmod:
	chmod +x *.sh

.PHONY: clean

clean:
	rm -rf $(OBJS) obj/*.optrpt *.optrpt
