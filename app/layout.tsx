import type { Metadata, Viewport } from "next";
import "./globals.css";
export const metadata: Metadata = {
  title: "ADV Rewards",
  description: "Recompensas diarias ADV en World Chain",
  applicationName: "ADV Rewards"
};
export const viewport: Viewport = { width: "device-width", initialScale: 1, themeColor: "#100d1b" };
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="es"><body>{children}</body></html>;
}
