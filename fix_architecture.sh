#!/usr/bin/env bash
# =============================================================================
# fix_architecture.sh
# BrightClean – Fix Clean Architecture Violations
# Phase 1: Add missing data/ layer to all features
# Phase 2: Move misplaced models from presentation/ to data/
# Compatible with: macOS, Linux, Git Bash (Windows)
# =============================================================================

# --- Configuration -----------------------------------------------------------
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/brightcleanproject"
LIB="$PROJECT_ROOT/lib"
FEATURES=("admin" "agent" "auth" "customer" "driver")

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

log_info()  { echo -e "${CYAN}[INFO]${NC}  $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_skip()  { echo -e "${YELLOW}[SKIP]${NC}  $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo ""
echo -e "${CYAN}================================================================${NC}"
echo -e "${CYAN}  BrightClean – Fix Clean Architecture Violations${NC}"
echo -e "${CYAN}================================================================${NC}"
echo ""

# --- Validate project root ---------------------------------------------------
if [ ! -d "$LIB" ]; then
  log_error "lib/ directory not found at: $LIB"
  log_error "Place this script in the BrightClean workspace root."
  exit 1
fi
log_info "Project root: $PROJECT_ROOT"
echo ""


# =============================================================================
# PHASE 1: Add missing data/ layers to all features
# =============================================================================
echo -e "${CYAN}┌──────────────────────────────────────────────────────────────┐${NC}"
echo -e "${CYAN}│  PHASE 1: Create Missing Data Layers                       │${NC}"
echo -e "${CYAN}└──────────────────────────────────────────────────────────────┘${NC}"
echo ""

# --- Pseudo-code content per subfolder (associative arrays) ---

declare -A DS_EXAMPLES
DS_EXAMPLES["admin"]='AdminRemoteDataSource'
DS_EXAMPLES["agent"]='AgentRemoteDataSource'
DS_EXAMPLES["auth"]='AuthRemoteDataSource'
DS_EXAMPLES["customer"]='CustomerRemoteDataSource'
DS_EXAMPLES["driver"]='DriverRemoteDataSource'

declare -A MODEL_EXAMPLES
MODEL_EXAMPLES["admin"]='DashboardStatsModel'
MODEL_EXAMPLES["agent"]='LaundryOrderModel'
MODEL_EXAMPLES["auth"]='UserCredentialModel'
MODEL_EXAMPLES["customer"]='OrderModel'
MODEL_EXAMPLES["driver"]='DeliveryTaskModel'

declare -A REPO_EXAMPLES
REPO_EXAMPLES["admin"]='AdminRepositoryImpl'
REPO_EXAMPLES["agent"]='AgentRepositoryImpl'
REPO_EXAMPLES["auth"]='AuthRepositoryImpl'
REPO_EXAMPLES["customer"]='CustomerRepositoryImpl'
REPO_EXAMPLES["driver"]='DriverRepositoryImpl'

for feature in "${FEATURES[@]}"; do
  FEATURE_DIR="$LIB/features/$feature"

  if [ ! -d "$FEATURE_DIR" ]; then
    log_warn "Feature directory not found, skipping: $feature"
    continue
  fi

  log_info "Processing feature: ${GREEN}$feature${NC}"

  # --- data/datasources/ ---
  DS_DIR="$FEATURE_DIR/data/datasources"
  mkdir -p "$DS_DIR"
  DS_PLACEHOLDER="$DS_DIR/placeholder.txt"
  if [ ! -f "$DS_PLACEHOLDER" ]; then
    DS_CLASS="${DS_EXAMPLES[$feature]}"
    cat > "$DS_PLACEHOLDER" <<EOF
# data/datasources/ — Data Sources
# ==================================
# This folder contains the classes that directly communicate with
# external systems: REST APIs, local databases (sqflite), or
# third-party services (Firebase, Google Maps, etc.).
#
# Data Sources are called by Repository implementations and should
# NEVER be imported by the Presentation or Domain layers directly.
#
# --- Dart Pseudo-Code Example: ${DS_CLASS} ---
#
# abstract class ${DS_CLASS} {
#   Future<Map<String, dynamic>> fetchData();
# }
#
# class ${DS_CLASS}Impl implements ${DS_CLASS} {
#   final http.Client client;
#
#   ${DS_CLASS}Impl({required this.client});
#
#   @override
#   Future<Map<String, dynamic>> fetchData() async {
#     final response = await client.get(
#       Uri.parse('https://api.brightclean.com/${feature}/...'),
#     );
#     if (response.statusCode == 200) {
#       return json.decode(response.body);
#     }
#     throw ServerException('Failed to fetch $feature data');
#   }
# }
EOF
    log_ok "  Created: $feature/data/datasources/placeholder.txt"
  else
    log_skip "  Already exists: $feature/data/datasources/placeholder.txt"
  fi

  # --- data/models/ ---
  MODELS_DIR="$FEATURE_DIR/data/models"
  mkdir -p "$MODELS_DIR"
  MODELS_PLACEHOLDER="$MODELS_DIR/placeholder.txt"
  if [ ! -f "$MODELS_PLACEHOLDER" ]; then
    MODEL_CLASS="${MODEL_EXAMPLES[$feature]}"
    cat > "$MODELS_PLACEHOLDER" <<EOF
# data/models/ — Data Transfer Objects (DTOs)
# ==============================================
# This folder contains model classes that handle serialization and
# deserialization of data (JSON ↔ Dart objects). These models are
# the "data" representation used by the Data layer.
#
# Models typically extend or map to Domain Entities but add
# serialization logic (fromJson, toJson, toMap, fromMap).
#
# --- Dart Pseudo-Code Example: ${MODEL_CLASS} ---
#
# import '../../domain/entities/${feature}_entity.dart';
#
# class ${MODEL_CLASS} extends ${feature^}Entity {
#   const ${MODEL_CLASS}({
#     required super.id,
#     required super.name,
#     // ... other fields
#   });
#
#   factory ${MODEL_CLASS}.fromJson(Map<String, dynamic> json) {
#     return ${MODEL_CLASS}(
#       id: json['id'] as String,
#       name: json['name'] as String,
#     );
#   }
#
#   Map<String, dynamic> toJson() {
#     return {
#       'id': id,
#       'name': name,
#     };
#   }
# }
EOF
    log_ok "  Created: $feature/data/models/placeholder.txt"
  else
    log_skip "  Already exists: $feature/data/models/placeholder.txt"
  fi

  # --- data/repositories/ ---
  REPOS_DIR="$FEATURE_DIR/data/repositories"
  mkdir -p "$REPOS_DIR"
  REPOS_PLACEHOLDER="$REPOS_DIR/placeholder.txt"
  if [ ! -f "$REPOS_PLACEHOLDER" ]; then
    REPO_CLASS="${REPO_EXAMPLES[$feature]}"
    cat > "$REPOS_PLACEHOLDER" <<EOF
# data/repositories/ — Repository Implementations
# ===================================================
# This folder contains the CONCRETE implementations of the
# Repository interfaces defined in domain/repositories/.
#
# The Repository pattern bridges the Domain and Data layers:
#   - Domain defines the interface (what methods are available)
#   - Data implements them (how data is actually fetched/stored)
#
# Repositories decide whether to fetch from remote API, local cache,
# or a combination of both (offline-first strategy).
#
# --- Dart Pseudo-Code Example: ${REPO_CLASS} ---
#
# import '../../domain/repositories/${feature}_repository.dart';
# import '../datasources/${feature}_remote_datasource.dart';
# import '../datasources/${feature}_local_datasource.dart';
#
# class ${REPO_CLASS} implements ${feature^}Repository {
#   final ${DS_EXAMPLES[$feature]} remoteDataSource;
#   // final ${feature^}LocalDataSource localDataSource; // optional
#
#   const ${REPO_CLASS}({required this.remoteDataSource});
#
#   @override
#   Future<void> performAction(/* params */) async {
#     try {
#       final result = await remoteDataSource.fetchData();
#       // Optionally cache locally:
#       // await localDataSource.cache(result);
#       return result;
#     } catch (e) {
#       // Fallback to local cache or rethrow
#       rethrow;
#     }
#   }
# }
EOF
    log_ok "  Created: $feature/data/repositories/placeholder.txt"
  else
    log_skip "  Already exists: $feature/data/repositories/placeholder.txt"
  fi

  echo ""
done


# =============================================================================
# PHASE 2: Move misplaced models from presentation/ to data/
# =============================================================================
echo -e "${CYAN}┌──────────────────────────────────────────────────────────────┐${NC}"
echo -e "${CYAN}│  PHASE 2: Fix Misplaced Models                             │${NC}"
echo -e "${CYAN}└──────────────────────────────────────────────────────────────┘${NC}"
echo ""

# Search ALL features for presentation/models/ directories
for feature in "${FEATURES[@]}"; do
  SRC_MODELS="$LIB/features/$feature/presentation/models"
  DEST_MODELS="$LIB/features/$feature/data/models"

  if [ -d "$SRC_MODELS" ]; then
    log_info "Found misplaced models in: features/$feature/presentation/models/"

    # Ensure destination exists
    mkdir -p "$DEST_MODELS"

    # Move each file individually (don't overwrite existing files)
    FILES_MOVED=0
    for file in "$SRC_MODELS"/*; do
      [ ! -e "$file" ] && continue  # skip if glob matched nothing

      filename=$(basename "$file")
      dest_file="$DEST_MODELS/$filename"

      if [ -e "$dest_file" ]; then
        log_skip "  Already exists in data/models/, skipping: $filename"
      else
        mv "$file" "$dest_file"
        log_ok "  Moved: presentation/models/$filename → data/models/$filename"
        FILES_MOVED=$((FILES_MOVED + 1))
      fi
    done

    # Remove source directory if now empty
    if [ -d "$SRC_MODELS" ] && [ -z "$(ls -A "$SRC_MODELS")" ]; then
      rm -rf "$SRC_MODELS"
      log_ok "  Removed empty: features/$feature/presentation/models/"
    elif [ -d "$SRC_MODELS" ]; then
      log_warn "  features/$feature/presentation/models/ still has files — check manually"
    fi

    if [ "$FILES_MOVED" -gt 0 ]; then
      echo ""
      echo -e "  ${YELLOW}⚠  IMPORTANT: Update imports in Dart files!${NC}"
      echo -e "  ${YELLOW}   Old: import '...presentation/models/...'${NC}"
      echo -e "  ${YELLOW}   New: import '...data/models/...'${NC}"
    fi

    echo ""
  else
    log_skip "No misplaced models found in: features/$feature/presentation/"
  fi
done


# =============================================================================
# DONE
# =============================================================================
echo ""
echo -e "${CYAN}================================================================${NC}"
echo -e "${GREEN}  ✓ Architecture fixes complete!${NC}"
echo -e "${CYAN}================================================================${NC}"
echo ""
echo -e "  ${CYAN}What was fixed:${NC}"
echo -e "  1. ${GREEN}data/datasources/${NC}  created for all features"
echo -e "  2. ${GREEN}data/models/${NC}       created for all features"
echo -e "  3. ${GREEN}data/repositories/${NC} created for all features"
echo -e "  4. ${GREEN}Misplaced models${NC}   moved from presentation/ to data/"
echo ""
echo -e "  ${CYAN}Next steps:${NC}"
echo -e "  1. Run ${YELLOW}flutter analyze${NC} to check for broken imports."
echo -e "  2. Update any imports from ${RED}presentation/models/${NC}"
echo -e "     to ${GREEN}../../data/models/${NC} (the script will show which files)."
echo -e "  3. Begin implementing model classes in each ${GREEN}data/models/${NC} folder."
echo ""
