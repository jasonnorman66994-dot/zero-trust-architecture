#!/usr/bin/env python3
"""
Generate HTML documentation from Markdown files
"""
import os
import markdown
from pathlib import Path

# Configuration
BASE_DIR = Path(__file__).parent
MD_FILES = [
    'README.md',
    'ARCHITECTURE.md',
    'CI-CD-SETUP.md',
    'TEST-RESULTS.md',
    'zero-trust-cli-guide.md'
]

# HTML template
HTML_TEMPLATE = """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{title} - Zero Trust Architecture</title>
    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}
        
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            line-height: 1.6;
            color: #333;
            background: #f5f5f5;
        }}
        
        .container {{
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            box-shadow: 0 0 20px rgba(0,0,0,0.1);
        }}
        
        header {{
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 2rem;
            text-align: center;
        }}
        
        header h1 {{
            font-size: 2.5rem;
            margin-bottom: 0.5rem;
        }}
        
        nav {{
            background: #2c3e50;
            padding: 1rem;
            position: sticky;
            top: 0;
            z-index: 100;
        }}
        
        nav ul {{
            list-style: none;
            display: flex;
            justify-content: center;
            flex-wrap: wrap;
            gap: 1rem;
        }}
        
        nav a {{
            color: white;
            text-decoration: none;
            padding: 0.5rem 1rem;
            border-radius: 4px;
            transition: background 0.3s;
        }}
        
        nav a:hover {{
            background: rgba(255,255,255,0.1);
        }}
        
        nav a.active {{
            background: #667eea;
        }}
        
        main {{
            padding: 2rem;
            min-height: calc(100vh - 200px);
        }}
        
        h1 {{
            color: #2c3e50;
            margin: 2rem 0 1rem 0;
            padding-bottom: 0.5rem;
            border-bottom: 3px solid #667eea;
        }}
        
        h2 {{
            color: #34495e;
            margin: 1.5rem 0 1rem 0;
            padding-bottom: 0.3rem;
            border-bottom: 2px solid #ddd;
        }}
        
        h3 {{
            color: #555;
            margin: 1rem 0 0.5rem 0;
        }}
        
        pre {{
            background: #f8f9fa;
            border: 1px solid #dee2e6;
            border-left: 4px solid #667eea;
            padding: 1rem;
            overflow-x: auto;
            border-radius: 4px;
            margin: 1rem 0;
        }}
        
        code {{
            background: #f8f9fa;
            padding: 0.2rem 0.4rem;
            border-radius: 3px;
            font-family: 'Courier New', monospace;
            font-size: 0.9em;
        }}
        
        pre code {{
            background: none;
            padding: 0;
        }}
        
        table {{
            width: 100%;
            border-collapse: collapse;
            margin: 1rem 0;
            background: white;
        }}
        
        th, td {{
            padding: 0.75rem;
            border: 1px solid #ddd;
            text-align: left;
        }}
        
        th {{
            background: #667eea;
            color: white;
            font-weight: bold;
        }}
        
        tr:nth-child(even) {{
            background: #f8f9fa;
        }}
        
        a {{
            color: #667eea;
            text-decoration: none;
        }}
        
        a:hover {{
            text-decoration: underline;
        }}
        
        blockquote {{
            border-left: 4px solid #667eea;
            padding-left: 1rem;
            margin: 1rem 0;
            color: #555;
            background: #f8f9fa;
            padding: 1rem;
        }}
        
        ul, ol {{
            margin: 1rem 0;
            padding-left: 2rem;
        }}
        
        li {{
            margin: 0.5rem 0;
        }}
        
        footer {{
            background: #2c3e50;
            color: white;
            text-align: center;
            padding: 1.5rem;
            margin-top: 2rem;
        }}
        
        .home-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 2rem;
            margin: 2rem 0;
        }}
        
        .card {{
            background: #f8f9fa;
            padding: 1.5rem;
            border-radius: 8px;
            border-left: 4px solid #667eea;
            transition: transform 0.3s, box-shadow 0.3s;
        }}
        
        .card:hover {{
            transform: translateY(-5px);
            box-shadow: 0 5px 20px rgba(0,0,0,0.1);
        }}
        
        .card h3 {{
            color: #667eea;
            margin-top: 0;
        }}
        
        .badge {{
            display: inline-block;
            padding: 0.25rem 0.5rem;
            background: #667eea;
            color: white;
            border-radius: 3px;
            font-size: 0.8rem;
            margin-right: 0.5rem;
        }}
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>🔐 Zero Trust Architecture</h1>
            <p>Complete Implementation & Documentation</p>
        </header>
        
        <nav>
            <ul>
                <li><a href="index.html" {index_active}>Home</a></li>
                <li><a href="README.html" {readme_active}>Overview</a></li>
                <li><a href="ARCHITECTURE.html" {arch_active}>Architecture</a></li>
                <li><a href="zero-trust-cli-guide.html" {cli_active}>CLI Guide</a></li>
                <li><a href="CI-CD-SETUP.html" {cicd_active}>CI/CD Setup</a></li>
                <li><a href="TEST-RESULTS.html" {test_active}>Test Results</a></li>
            </ul>
        </nav>
        
        <main>
            {content}
        </main>
        
        <footer>
            <p>Zero Trust Architecture Documentation</p>
            <p>Built with ❤️ for cybersecurity education and awareness</p>
        </footer>
    </div>
</body>
</html>
"""

INDEX_CONTENT = """
<h1>🎯 Zero Trust Architecture - Documentation Hub</h1>

<p>Welcome to the complete documentation for the Zero Trust Architecture implementation. This project demonstrates comprehensive zero trust security principles using Linux CLI tools.</p>

<div class="home-grid">
    <div class="card">
        <h3>📖 Overview</h3>
        <p>Get started with the project overview, quick start guide, and component descriptions.</p>
        <p><a href="README.html">Read the README →</a></p>
    </div>
    
    <div class="card">
        <h3>🏗️ Architecture</h3>
        <p>Detailed architecture documentation including design patterns, components, and implementation details.</p>
        <p><a href="ARCHITECTURE.html">View Architecture →</a></p>
    </div>
    
    <div class="card">
        <h3>💻 CLI Guide</h3>
        <p>Step-by-step command-line guide for implementing and using zero trust components.</p>
        <p><a href="zero-trust-cli-guide.html">CLI Guide →</a></p>
    </div>
    
    <div class="card">
        <h3>🔄 CI/CD Setup</h3>
        <p>Continuous Integration and Deployment setup instructions and best practices.</p>
        <p><a href="CI-CD-SETUP.html">CI/CD Guide →</a></p>
    </div>
    
    <div class="card">
        <h3>✅ Test Results</h3>
        <p>Comprehensive test results, validation reports, and security assessments.</p>
        <p><a href="TEST-RESULTS.html">View Tests →</a></p>
    </div>
</div>

<h2>🚀 Quick Start</h2>
<pre><code># Clone the repository
git clone https://github.com/jasonnorman66994-dot/zero-trust-architecture.git
cd zero-trust-architecture

# Run the complete interactive demo
./run-zero-trust-demo.sh

# Or test individual components
./zero-trust-policy.sh alice database 127.0.0.1
./security-monitoring.sh
sudo ./network-namespace-demo.sh
</code></pre>

<h2>🔐 Key Zero Trust Principles</h2>
<ul>
    <li><strong>Never Trust, Always Verify</strong> - Every request is authenticated and authorized</li>
    <li><strong>Least Privilege Access</strong> - Users and services have minimal necessary permissions</li>
    <li><strong>Micro-segmentation</strong> - Network isolation using namespaces</li>
    <li><strong>Continuous Monitoring</strong> - Real-time security posture visibility</li>
    <li><strong>Encrypted Communication</strong> - Mutual TLS (mTLS) for all connections</li>
</ul>

<h2>📦 Main Components</h2>
<ul>
    <li><strong>Policy Enforcement Engine</strong> - Validates every access request</li>
    <li><strong>Security Monitoring Dashboard</strong> - Real-time visibility into security posture</li>
    <li><strong>Network Micro-Segmentation</strong> - Creates isolated network environments</li>
    <li><strong>Mutual TLS Infrastructure</strong> - Complete certificate chain for encrypted communication</li>
    <li><strong>Identity Management</strong> - Strong cryptographic authentication</li>
</ul>
"""


def convert_md_to_html(md_file, output_file, active_page=''):
    """Convert a markdown file to HTML"""
    # Read markdown content
    with open(md_file, 'r', encoding='utf-8') as f:
        md_content = f.read()
    
    # Convert markdown to HTML
    md_processor = markdown.Markdown(extensions=['extra', 'codehilite', 'tables', 'fenced_code'])
    html_content = md_processor.convert(md_content)
    
    # Get title from filename
    title = md_file.stem.replace('-', ' ').title()
    
    # Set active navigation
    nav_active = {
        'index_active': 'class="active"' if active_page == 'index' else '',
        'readme_active': 'class="active"' if active_page == 'README' else '',
        'arch_active': 'class="active"' if active_page == 'ARCHITECTURE' else '',
        'cli_active': 'class="active"' if active_page == 'zero-trust-cli-guide' else '',
        'cicd_active': 'class="active"' if active_page == 'CI-CD-SETUP' else '',
        'test_active': 'class="active"' if active_page == 'TEST-RESULTS' else '',
    }
    
    # Generate final HTML
    final_html = HTML_TEMPLATE.format(
        title=title,
        content=html_content,
        **nav_active
    )
    
    # Write HTML file
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(final_html)
    
    print(f"✓ Generated: {output_file}")


def generate_index():
    """Generate index.html homepage"""
    nav_active = {
        'index_active': 'class="active"',
        'readme_active': '',
        'arch_active': '',
        'cli_active': '',
        'cicd_active': '',
        'test_active': '',
    }
    
    final_html = HTML_TEMPLATE.format(
        title='Documentation Hub',
        content=INDEX_CONTENT,
        **nav_active
    )
    
    output_file = BASE_DIR / 'index.html'
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(final_html)
    
    print(f"✓ Generated: {output_file}")


def main():
    """Main function to generate all HTML files"""
    print("Generating HTML documentation from Markdown files...")
    print("=" * 60)
    
    # Generate index page
    generate_index()
    
    # Convert each markdown file
    for md_filename in MD_FILES:
        md_file = BASE_DIR / md_filename
        html_filename = md_filename.replace('.md', '.html')
        output_file = BASE_DIR / html_filename
        
        if md_file.exists():
            active_page = md_file.stem
            convert_md_to_html(md_file, output_file, active_page)
        else:
            print(f"✗ Warning: {md_file} not found, skipping...")
    
    print("=" * 60)
    print("HTML generation complete!")
    print("\nGenerated files:")
    print("  - index.html (Homepage)")
    for md_file in MD_FILES:
        html_file = md_file.replace('.md', '.html')
        print(f"  - {html_file}")
    print("\nOpen index.html in your browser to view the documentation.")


if __name__ == '__main__':
    main()
