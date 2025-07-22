import type { Metadata } from "next";
import "./globals.css";
import { Providers } from "./providers";
import ErrorMonitor from "../components/ErrorMonitor";

export const metadata: Metadata = {
  title: "Uniswap V2 DApp - Polygon",
  description: "A decentralized exchange built on Uniswap V2 on Polygon Network",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="antialiased" suppressHydrationWarning>
        <ErrorMonitor />
        <Providers>
          {children}
        </Providers>
      </body>
    </html>
  );
}
