import { defineConfig } from 'vitepress'

export default defineConfig({
  title: "zon.zig",
  description: "A simple, direct Zig library for reading and writing ZON files",
  base: '/zon.zig/',
  
  head: [
    ['link', { rel: 'icon', type: 'image/svg+xml', href: '/zon.zig/logo.svg' }],
    ['meta', { name: 'theme-color', content: '#f7a41d' }],
    ['meta', { property: 'og:type', content: 'website' }],
    ['meta', { property: 'og:title', content: 'zon.zig' }],
    ['meta', { property: 'og:description', content: 'A simple, direct Zig library for reading and writing ZON files' }],
    ['meta', { property: 'og:url', content: 'https://muhammad-fiaz.github.io/zon.zig/' }],
  ],

  themeConfig: {
    logo: '/logo.svg',
    
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Guide', link: '/guide/getting-started' },
      { text: 'API', link: '/api/' },
      { text: 'Examples', link: '/guide/examples' },
      {
        text: 'v0.0.1',
        items: [
          { text: 'Changelog', link: 'https://github.com/muhammad-fiaz/zon.zig/releases' },
          { text: 'Contributing', link: 'https://github.com/muhammad-fiaz/zon.zig/blob/main/CONTRIBUTING.md' }
        ]
      }
    ],

    sidebar: {
      '/guide/': [
        {
          text: 'Introduction',
          items: [
            { text: 'What is zon.zig?', link: '/guide/' },
            { text: 'Getting Started', link: '/guide/getting-started' },
            { text: 'Installation', link: '/guide/installation' }
          ]
        },
        {
          text: 'Core Usage',
          items: [
            { text: 'Basic Usage', link: '/guide/basic-usage' },
            { text: 'Reading Files', link: '/guide/reading' },
            { text: 'Writing Files', link: '/guide/writing' },
            { text: 'Nested Paths', link: '/guide/nested-paths' },
            { text: 'Identifier Values', link: '/guide/identifier-values' }
          ]
        },
        {
          text: 'Advanced',
          items: [
            { text: 'Find & Replace', link: '/guide/find-replace' },
            { text: 'Array Operations', link: '/guide/arrays' },
            { text: 'Merge & Clone', link: '/guide/merge-clone' },
            { text: 'Pretty Print', link: '/guide/pretty-print' },
            { text: 'Error Handling', link: '/guide/error-handling' },
            { text: 'Examples', link: '/guide/examples' }
          ]
        }
      ],
      '/api/': [
        {
          text: 'API Reference',
          items: [
            { text: 'Overview', link: '/api/' },
            { text: 'Module Functions', link: '/api/module' },
            { text: 'Document', link: '/api/document' },
            { text: 'Value Types', link: '/api/value' }
          ]
        }
      ]
    },

    socialLinks: [
      { icon: 'github', link: 'https://github.com/muhammad-fiaz/zon.zig' }
    ],

    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Copyright © 2025 Muhammad Fiaz'
    },

    search: {
      provider: 'local'
    },

    editLink: {
      pattern: 'https://github.com/muhammad-fiaz/zon.zig/edit/main/docs/:path',
      text: 'Edit this page on GitHub'
    }
  }
})
