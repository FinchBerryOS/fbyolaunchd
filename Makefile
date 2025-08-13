OUTPUT_DIR=output

# Zielbetriebssysteme und Architekturen
OSES=linux freebsd
ARCHS=arm arm64 x86 x64

# Mapping ARCH → GOARCH (für Go-Build)
ARCH_MAP_arm=arm
ARCH_MAP_arm64=arm64
ARCH_MAP_x86=386
ARCH_MAP_x64=amd64

all: build-all

# 1️⃣ Alles für alle OS + Archs + Services bauen
build-all:
	@for os in $(OSES); do \
		for arch in $(ARCHS); do \
			goarch=$$(eval echo \$${ARCH_MAP_$$arch}); \
			for dir in $$(find cmd -mindepth 1 -maxdepth 1 -type d -exec basename {} \;); do \
				echo "🔨 Building $$dir for $$os/$$arch (GOARCH=$$goarch)..."; \
				mkdir -p $(OUTPUT_DIR)/$$os/$$arch; \
				GOOS=$$os GOARCH=$$goarch go build -o $(OUTPUT_DIR)/$$os/$$arch/$$dir ./cmd/$$dir; \
			done \
		done \
	done

# 2️⃣ Nur ein Service für ein OS + Arch
# Beispiel: make build OS=freebsd ARCH=x64 SERVICE=notifyd
build:
	@if [ -z "$(OS)" ] || [ -z "$(ARCH)" ] || [ -z "$(SERVICE)" ]; then \
		echo "❌ Please specify OS, ARCH and SERVICE. Example:"; \
		echo "   make build OS=freebsd ARCH=x64 SERVICE=notifyd"; \
		exit 1; \
	fi
	@goarch=$$(eval echo \$${ARCH_MAP_$(ARCH)}); \
	echo "🔨 Building $(SERVICE) for $(OS)/$(ARCH) (GOARCH=$$goarch)..."; \
	mkdir -p $(OUTPUT_DIR)/$(OS)/$(ARCH); \
	GOOS=$(OS) GOARCH=$$goarch go build -o $(OUTPUT_DIR)/$(OS)/$(ARCH)/$(SERVICE) ./cmd/$(SERVICE)

# 3️⃣ Alle Services für ein OS + Arch
# Beispiel: make build-arch OS=linux ARCH=arm64
build-arch:
	@if [ -z "$(OS)" ] || [ -z "$(ARCH)" ]; then \
		echo "❌ Please specify OS and ARCH. Example:"; \
		echo "   make build-arch OS=linux ARCH=arm64"; \
		exit 1; \
	fi
	@goarch=$$(eval echo \$${ARCH_MAP_$(ARCH)}); \
	for dir in $$(find cmd -mindepth 1 -maxdepth 1 -type d -exec basename {} \;); do \
		echo "🔨 Building $$dir for $(OS)/$(ARCH) (GOARCH=$$goarch)..."; \
		mkdir -p $(OUTPUT_DIR)/$(OS)/$(ARCH); \
		GOOS=$(OS) GOARCH=$$goarch go build -o $(OUTPUT_DIR)/$(OS)/$(ARCH)/$$dir ./cmd/$$dir; \
	done

clean:
	@echo "🧹 Cleaning up..."
	rm -rf $(OUTPUT_DIR)

run: build-all
	@echo "🚀 Available binaries in $(OUTPUT_DIR):"
	@find $(OUTPUT_DIR) -type f -perm +111 -exec ls -lh {} \;

.PHONY: all build-all build build-arch clean run
