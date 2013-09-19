Nodes CMS

- coffeescript
- express
- mongodb


Example json structure in mongodb

    layouts = [
      { _id: "#1", name: "main" }
    ]
    sublayouts = [
      { _id: "#2", name: "navbar" }
      { _id: "#3", name: "content" }
      { _id: "#4", name: "navbar_github" }
    ]
    pages = [
      {
        parent: null
        id: "#5",
        name: "Home"
        url: "/",
        layout:  "#1"
        sublayouts: [
          { placeholder: "nav", id: "#2" },
          { placeholder: "content", id: "#3" }
          { placeholder: "navbar_github", id: "#4" }
        ]
        fields: { title: "Site Name" }
      },
      {
        parent: "#5"
        id: "#6",
        name: "Services"
        url: "/services",
        layout:  "#1"
        sublayouts: [
          { placeholder: "nav", id: "#2" }
          { placeholder: "navbar_github", id: "#4" }
        ]
        fields: { title: "Site Name" }
      }
    ]
   