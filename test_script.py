import re

content = """
    return Scaffold(
      backgroundColor: backgroundColor ?? AppTheme.lightBackground,
      appBar: appBar,
      body: Padding(
        padding: EdgeInsets.only(bottom: bodyPadding),
        child: body,
      ),
      floatingActionButton: floatingActionButton != null 
          ? Padding(
              padding: EdgeInsets.only(bottom: fabPadding),
              child: floatingActionButton,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
"""
# Replace body with extendBody and bottomNavigationBar
content = content.replace("body: Padding(\n        padding: EdgeInsets.only(bottom: bodyPadding),\n        child: body,\n      ),", "extendBody: true,\n      body: body,\n      bottomNavigationBar: SizedBox(height: bodyPadding, width: double.infinity),")
print(content)
