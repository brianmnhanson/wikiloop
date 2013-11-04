package org.brianmnhanson.wikiloop;

import java.io.IOException;
import java.util.HashSet;
import java.util.Set;

import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.nodes.Node;
import org.jsoup.nodes.TextNode;
import org.jsoup.select.Elements;

public class WikiLoop
{

	public static void main(String[] args) throws IOException
	{
		final Set<String> pages = new HashSet<>();
		pages.add("/wiki/Philosophy");
		String page = "/wiki/Special:Random";
		for (int i = 0; i < 30; i++)
		{
			final Document doc = Jsoup.connect("http://en.wikipedia.org" + page).get();
			System.out.println(doc.title());
			if (pages.contains(page))
				return;
			pages.add(page);
			final Elements paragraphs = doc.select("#mw-content-text > p");
			for (Element paragraph : paragraphs)
			{
				for (Element element : paragraph.select(".nowrap, sup, i, [xml:lang], [class^=IPA]"))
					element.remove();
				final Element anchor = new WikiLoop().scanForAnchor(paragraph);
				if (anchor != null)
				{
					page = anchor.attr("href");
					break;
				}
			}
		}
	}

	private int	parens	= 0;


	private Element scanForAnchor(Element e)
	{
		if (e.tagName().equals("a") && parens == 0)
			return e;
		for (Node child : e.childNodes())
		{
			if (child instanceof Element)
			{
				final Element anchor = scanForAnchor((Element) child);
				if (anchor != null)
					return anchor;
			}
			else if (child instanceof TextNode)
				scanText(((TextNode) child).text());
		}
		return null;
	}


	private void scanText(final String text)
	{
		for (int i = 0; i < text.length(); i++)
		{
			if (text.charAt(i) == '(')
				parens++;
			else if (text.charAt(i) == ')')
				parens--;
		}
	}

}
