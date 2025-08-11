#!/usr/bin/env python3
"""
🔍 Language Detection System for SAST Scanner Recommendations
Automatically detects project languages and recommends optimal SAST scanners.
"""

import os
import sys
import json
import argparse
from pathlib import Path
from typing import Dict, List, Set
from collections import defaultdict

# Language detection patterns
LANGUAGE_PATTERNS = {
    'javascript': {
        'extensions': ['.js', '.jsx', '.mjs'],
        'files': ['package.json', 'package-lock.json', 'yarn.lock'],
        'scanners': ['codeql', 'eslint', 'semgrep'],
        'priority': 1
    },
    'typescript': {
        'extensions': ['.ts', '.tsx'],
        'files': ['tsconfig.json', 'package.json'],
        'scanners': ['codeql', 'eslint', 'semgrep'],
        'priority': 1
    },
    'python': {
        'extensions': ['.py', '.pyw', '.pyi'],
        'files': ['requirements.txt', 'setup.py', 'pyproject.toml', 'Pipfile'],
        'scanners': ['codeql', 'bandit', 'semgrep'],
        'priority': 1
    },
    'java': {
        'extensions': ['.java'],
        'files': ['pom.xml', 'build.gradle', 'gradle.properties'],
        'scanners': ['codeql', 'semgrep'],
        'priority': 1
    },
    'go': {
        'extensions': ['.go'],
        'files': ['go.mod', 'go.sum', 'Gopkg.toml'],
        'scanners': ['codeql', 'semgrep'],
        'priority': 1
    },
    'csharp': {
        'extensions': ['.cs', '.csx', '.vb'],
        'files': ['*.csproj', '*.vbproj', '*.sln', 'packages.config'],
        'scanners': ['codeql', 'semgrep'],
        'priority': 1
    },
    'ruby': {
        'extensions': ['.rb', '.rbw'],
        'files': ['Gemfile', 'Gemfile.lock', '*.gemspec'],
        'scanners': ['semgrep'],
        'priority': 2
    },
    'php': {
        'extensions': ['.php', '.phtml', '.php3', '.php4', '.php5'],
        'files': ['composer.json', 'composer.lock'],
        'scanners': ['semgrep'],
        'priority': 2
    },
    'cpp': {
        'extensions': ['.cpp', '.cxx', '.cc', '.c', '.h', '.hpp', '.hxx'],
        'files': ['CMakeLists.txt', 'Makefile', '*.vcxproj'],
        'scanners': ['codeql', 'semgrep'],
        'priority': 2
    },
    'kotlin': {
        'extensions': ['.kt', '.kts'],
        'files': ['build.gradle.kts'],
        'scanners': ['semgrep'],
        'priority': 2
    },
    'swift': {
        'extensions': ['.swift'],
        'files': ['Package.swift', '*.xcodeproj'],
        'scanners': ['semgrep'],
        'priority': 2
    },
    'rust': {
        'extensions': ['.rs'],
        'files': ['Cargo.toml', 'Cargo.lock'],
        'scanners': ['semgrep'],
        'priority': 2
    }
}

# Scanner capabilities and configurations
SCANNER_INFO = {
    'codeql': {
        'name': 'GitHub CodeQL',
        'description': 'Semantic code analysis engine',
        'languages': ['javascript', 'typescript', 'python', 'java', 'go', 'csharp', 'cpp'],
        'strength': 'Deep semantic analysis',
        'coverage': 'high',
        'performance': 'medium'
    },
    'semgrep': {
        'name': 'Semgrep',
        'description': 'Fast pattern-based static analysis',
        'languages': list(LANGUAGE_PATTERNS.keys()),
        'strength': 'Fast, customizable rules',
        'coverage': 'medium',
        'performance': 'high'
    },
    'bandit': {
        'name': 'Bandit',
        'description': 'Python security linter',
        'languages': ['python'],
        'strength': 'Python-specific security issues',
        'coverage': 'high',
        'performance': 'high'
    },
    'eslint': {
        'name': 'ESLint Security',
        'description': 'JavaScript/TypeScript security linting',
        'languages': ['javascript', 'typescript'],
        'strength': 'JavaScript ecosystem',
        'coverage': 'medium',
        'performance': 'high'
    }
}

class LanguageDetector:
    """Detects programming languages in a project directory."""
    
    def __init__(self, project_path: str, max_depth: int = 3):
        self.project_path = Path(project_path)
        self.max_depth = max_depth
        self.ignore_dirs = {
            '.git', '.svn', '.hg', '__pycache__', 'node_modules', 
            'venv', 'env', '.env', 'vendor', 'target', 'build',
            'dist', '.next', '.nuxt', 'coverage', '.coverage',
            'bin', 'obj', 'out'
        }
        
    def scan_directory(self) -> Dict[str, any]:
        """Scan directory and detect languages."""
        if not self.project_path.exists():
            raise FileNotFoundError(f"Project path does not exist: {self.project_path}")
        
        language_scores = defaultdict(int)
        file_counts = defaultdict(int)
        total_files = 0
        
        # Scan files
        for file_path in self._walk_files():
            total_files += 1
            file_ext = file_path.suffix.lower()
            
            # Check against language patterns
            for lang, patterns in LANGUAGE_PATTERNS.items():
                if file_ext in patterns['extensions']:
                    language_scores[lang] += patterns['priority']
                    file_counts[lang] += 1
        
        # Scan for special files
        for file_path in self._walk_files(depth=2):  # Shallow scan for config files
            file_name = file_path.name.lower()
            
            for lang, patterns in LANGUAGE_PATTERNS.items():
                if any(self._matches_pattern(file_name, pattern) for pattern in patterns['files']):
                    language_scores[lang] += patterns['priority'] * 2  # Config files get extra weight
        
        # Convert to results
        detected_languages = []
        for lang, score in sorted(language_scores.items(), key=lambda x: x[1], reverse=True):
            if score > 0:
                detected_languages.append({
                    'language': lang,
                    'confidence': min(score / max(language_scores.values()), 1.0),
                    'file_count': file_counts[lang],
                    'scanners': LANGUAGE_PATTERNS[lang]['scanners']
                })
        
        return {
            'detected_languages': detected_languages,
            'total_files_scanned': total_files,
            'scan_path': str(self.project_path),
            'recommendations': self._generate_recommendations(detected_languages)
        }
    
    def _walk_files(self, depth: int = None):
        """Walk through project files, respecting ignore patterns."""
        max_depth = depth or self.max_depth
        
        for root, dirs, files in os.walk(self.project_path):
            # Calculate current depth
            current_depth = len(Path(root).relative_to(self.project_path).parts)
            if current_depth >= max_depth:
                dirs.clear()  # Don't recurse deeper
                continue
            
            # Remove ignored directories
            dirs[:] = [d for d in dirs if d not in self.ignore_dirs]
            
            # Yield files
            for file_name in files:
                yield Path(root) / file_name
    
    def _matches_pattern(self, file_name: str, pattern: str) -> bool:
        """Check if file name matches pattern (supports simple wildcards)."""
        if '*' in pattern:
            import fnmatch
            return fnmatch.fnmatch(file_name, pattern)
        return file_name == pattern
    
    def _generate_recommendations(self, detected_languages: List[Dict]) -> Dict:
        """Generate scanner recommendations based on detected languages."""
        if not detected_languages:
            return {
                'recommended_scanners': ['semgrep'],
                'reasoning': 'Default recommendation - Semgrep supports multiple languages',
                'coverage': 'basic'
            }
        
        # Collect all recommended scanners
        all_scanners = set()
        high_confidence_languages = []
        
        for lang_info in detected_languages:
            if lang_info['confidence'] > 0.3:  # High confidence threshold
                high_confidence_languages.append(lang_info['language'])
                all_scanners.update(lang_info['scanners'])
        
        # Prioritize scanners based on coverage
        scanner_priority = {
            'codeql': 1,    # Highest priority for supported languages
            'semgrep': 2,   # Good general coverage
            'bandit': 3,    # Python-specific
            'eslint': 3     # JS/TS-specific
        }
        
        recommended = sorted(all_scanners, key=lambda x: scanner_priority.get(x, 99))
        
        # Generate reasoning
        reasoning_parts = []
        if 'python' in high_confidence_languages:
            reasoning_parts.append("Python detected - Bandit recommended for Python-specific security")
        if any(lang in high_confidence_languages for lang in ['javascript', 'typescript']):
            reasoning_parts.append("JavaScript/TypeScript detected - ESLint for ecosystem-specific linting")
        if any(lang in high_confidence_languages for lang in ['java', 'go', 'csharp', 'cpp']):
            reasoning_parts.append("Compiled language detected - CodeQL for deep semantic analysis")
        
        reasoning = "; ".join(reasoning_parts) or "Multi-language support with Semgrep"
        
        # Determine coverage level
        coverage = 'comprehensive' if len(recommended) >= 3 else 'standard' if len(recommended) >= 2 else 'basic'
        
        return {
            'recommended_scanners': recommended,
            'reasoning': reasoning,
            'coverage': coverage,
            'primary_languages': high_confidence_languages,
            'scanner_details': {scanner: SCANNER_INFO[scanner] for scanner in recommended if scanner in SCANNER_INFO}
        }

def generate_scanner_config(recommendations: Dict) -> Dict:
    """Generate scanner-specific configuration."""
    config = {
        'scanners': recommendations['recommended_scanners'],
        'scanner_config': {}
    }
    
    for scanner in recommendations['recommended_scanners']:
        if scanner == 'codeql':
            config['scanner_config']['codeql'] = {
                'languages': [lang for lang in recommendations['primary_languages'] 
                             if lang in SCANNER_INFO['codeql']['languages']],
                'queries': 'security-and-quality'
            }
        elif scanner == 'semgrep':
            config['scanner_config']['semgrep'] = {
                'config': 'auto',
                'rules': 'p/security-audit',
                'severity': 'ERROR'
            }
        elif scanner == 'bandit':
            config['scanner_config']['bandit'] = {
                'confidence': 'medium',
                'severity': 'medium',
                'format': 'sarif'
            }
        elif scanner == 'eslint':
            config['scanner_config']['eslint'] = {
                'config': 'security',
                'extensions': ['.js', '.jsx', '.ts', '.tsx']
            }
    
    return config

def main():
    """Command-line interface for language detection."""
    parser = argparse.ArgumentParser(
        description='🔍 Language Detection System for SAST Scanner Recommendations',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    python language-detector.py                    # Detect in current directory
    python language-detector.py /path/to/project   # Detect in specific directory
    python language-detector.py --json             # Output as JSON
    python language-detector.py --scanners-only    # Show only scanner recommendations
        """
    )
    
    parser.add_argument('path', nargs='?', default='.', 
                       help='Project path to analyze (default: current directory)')
    parser.add_argument('--json', action='store_true',
                       help='Output results as JSON')
    parser.add_argument('--scanners-only', action='store_true',
                       help='Show only scanner recommendations')
    parser.add_argument('--depth', type=int, default=3,
                       help='Maximum directory depth to scan (default: 3)')
    parser.add_argument('--verbose', '-v', action='store_true',
                       help='Enable verbose output')
    
    args = parser.parse_args()
    
    try:
        detector = LanguageDetector(args.path, max_depth=args.depth)
        results = detector.scan_directory()
        
        if args.json:
            print(json.dumps(results, indent=2))
        elif args.scanners_only:
            print(' '.join(results['recommendations']['recommended_scanners']))
        else:
            # Human-readable output
            print(f"🔍 Language Detection Results for: {results['scan_path']}")
            print(f"📁 Total files scanned: {results['total_files_scanned']}")
            print()
            
            if results['detected_languages']:
                print("🌐 Detected Languages:")
                for lang_info in results['detected_languages']:
                    confidence_bar = "█" * int(lang_info['confidence'] * 10)
                    print(f"  • {lang_info['language'].capitalize():12} "
                          f"[{confidence_bar:10}] "
                          f"{lang_info['confidence']:.1%} "
                          f"({lang_info['file_count']} files)")
                print()
            
            recommendations = results['recommendations']
            print("🛡️  Recommended SAST Scanners:")
            for scanner in recommendations['recommended_scanners']:
                if scanner in SCANNER_INFO:
                    info = SCANNER_INFO[scanner]
                    print(f"  • {info['name']:15} - {info['description']}")
            
            print(f"\n📊 Coverage Level: {recommendations['coverage'].title()}")
            print(f"💡 Reasoning: {recommendations['reasoning']}")
            
            if args.verbose and 'scanner_details' in recommendations:
                print("\n🔧 Scanner Details:")
                for scanner, info in recommendations['scanner_details'].items():
                    print(f"  {info['name']}:")
                    print(f"    Strength: {info['strength']}")
                    print(f"    Performance: {info['performance']}")
                    print(f"    Coverage: {info['coverage']}")
    
    except FileNotFoundError as e:
        print(f"❌ Error: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"❌ Unexpected error: {e}", file=sys.stderr)
        if args.verbose:
            import traceback
            traceback.print_exc()
        sys.exit(1)

if __name__ == '__main__':
    main()
