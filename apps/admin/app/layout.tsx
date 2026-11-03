import type { Metadata } from "next";
import { ThemeProvider } from "@/components/theme-provider";
import { Toaster } from "sonner";
import "./globals.css";

export const metadata: Metadata = {
  title: "ClassRoom Admin Panel",
  description: "Administrative dashboard for ClassRoom learning platform",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="bn" suppressHydrationWarning>
      <head>
        <script
          id="strip-extension-attrs"
          dangerouslySetInnerHTML={{
            __html: `
              (function() {
                try {
                  function clean(el) {
                    if (!el || el.nodeType !== 1) return;
                    if (el.hasAttribute('bis_skin_checked')) el.removeAttribute('bis_skin_checked');
                    if (el.hasAttribute('bis_register')) el.removeAttribute('bis_register');
                    var attrs = el.attributes;
                    if (attrs) {
                      for (var i = attrs.length - 1; i >= 0; i--) {
                        if (attrs[i] && attrs[i].name && attrs[i].name.indexOf('__processed_') === 0) {
                          el.removeAttribute(attrs[i].name);
                        }
                      }
                    }
                  }
                  var observer = new MutationObserver(function(mutations) {
                    for (var i = 0; i < mutations.length; i++) {
                      var m = mutations[i];
                      if (m.type === 'attributes') {
                        clean(m.target);
                      } else if (m.type === 'childList') {
                        for (var j = 0; j < m.addedNodes.length; j++) {
                          clean(m.addedNodes[j]);
                        }
                      }
                    }
                  });
                  observer.observe(document.documentElement, {
                    attributes: true,
                    childList: true,
                    subtree: true
                  });
                } catch(e) {}
              })();
            `,
          }}
        />
      </head>
      <body
        className="min-h-screen bg-background antialiased font-sans"
        suppressHydrationWarning
      >
        <ThemeProvider
          attribute="class"
          defaultTheme="system"
          enableSystem
          disableTransitionOnChange
        >
          {children}
          <Toaster richColors position="top-right" />
        </ThemeProvider>
      </body>
    </html>
  );
}

