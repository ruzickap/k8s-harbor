module.exports = {
  title: "Kubernetes and Harbor",
  description: "Kubernetes and Harbor",
  base: '/k8s-harbor/',
  head: [
    ['link', { rel: "icon", href: "/favicon.ico" }]
  ],
  themeConfig: {
    displayAllHeaders: true,
    lastUpdated: true,
    repo: 'ruzickap/k8s-harbor',
    docsDir: 'docs',
    editLinks: true,
    logo: '/harbor-horizontal-color.svg',
    nav: [
      { text: 'Home', link: '/' },
      {
        text: 'Harbor links',
        items: [
          { text: 'Harbor', link: 'https://goharbor.io/' },
          { text: 'Harbor Blog', link: 'https://goharbor.io/blogs/' },
          { text: 'Harbor Docs', link: 'https://goharbor.io/docs/' },
          { text: 'Harbor GitHub', link: 'https://github.com/goharbor/harbor/' },
          { text: 'Harbor Community', link: 'https://goharbor.io/community/' },
        ]
      }
    ],
    sidebar: [
      '/',
      '/part-01/',
      '/part-02/',
      '/part-03/',
      '/part-04/',
      '/part-05/',
      '/part-06/',
      '/part-07/',
      '/part-08/',
      '/part-09/',
    ]
  },
  plugins: [
    ['@vuepress/medium-zoom'],
    ['@vuepress/back-to-top'],
    ['seo']
  ]
}
