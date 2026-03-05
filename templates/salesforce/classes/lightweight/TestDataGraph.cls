/**
 * Manages test data DML with automatic dependency ordering.
 * 
 * ALL test data DML should flow through this class. Builders create records,
 * TestDataGraph handles insert ordering based on relationships.
 * 
 * Usage:
 *   TestDataGraph graph = new TestDataGraph();
 *   Account acc = new AccountBuilder().build();
 *   Contact con = new ContactBuilder().build();
 *   
 *   graph.register(acc);
 *   graph.register(con);
 *   graph.relate(con, Contact.AccountId, acc);
 *   graph.commit();
 *   
 *   // Now acc.Id and con.Id are populated on the original objects
 */
@IsTest
public class TestDataGraph {

    private List<Node> nodes = new List<Node>();
    private Map<SObject, Node> recordToNode = new Map<SObject, Node>();

    /**
     * Registers a record to be inserted. Returns this graph for chaining.
     */
    public TestDataGraph register(SObject record) {
        Node node = new Node(record);
        nodes.add(node);
        recordToNode.put(record, node);
        return this;
    }

    /**
     * Registers multiple records. Returns this graph for chaining.
     */
    public TestDataGraph registerAll(List<SObject> records) {
        for (SObject rec : records) {
            register(rec);
        }
        return this;
    }

    /**
     * Declares a lookup relationship: child.lookupField will be set to parent.Id after commit.
     * Returns this graph for chaining.
     */
    public TestDataGraph relate(SObject child, Schema.SObjectField lookupField, SObject parent) {
        Node childNode = recordToNode.get(child);
        Node parentNode = recordToNode.get(parent);
        
        if (childNode == null) {
            throw new TestDataGraphException('Child record not registered. Call register() first.');
        }
        if (parentNode == null) {
            throw new TestDataGraphException('Parent record not registered. Call register() first.');
        }
        
        childNode.addDependency(parentNode, lookupField);
        return this;
    }

    /**
     * Inserts all registered records in dependency order.
     * After commit, all original record references have their Id populated.
     */
    public void commit() {
        Set<Node> inserted = new Set<Node>();
        Integer maxIterations = nodes.size() * 2;
        Integer iteration = 0;
        
        while (inserted.size() < nodes.size()) {
            iteration++;
            if (iteration > maxIterations) {
                throw new TestDataGraphException(
                    'Circular dependency detected or unresolvable graph. ' +
                    'Inserted: ' + inserted.size() + ', Total: ' + nodes.size()
                );
            }
            
            List<Node> readyNodes = new List<Node>();
            for (Node node : nodes) {
                if (!inserted.contains(node) && node.dependenciesSatisfied(inserted)) {
                    readyNodes.add(node);
                }
            }
            
            if (readyNodes.isEmpty() && inserted.size() < nodes.size()) {
                throw new TestDataGraphException(
                    'Cannot resolve dependencies. Check for missing parent registrations.'
                );
            }
            
            Map<Schema.SObjectType, List<Node>> nodesBySObjectType = groupByType(readyNodes);
            for (Schema.SObjectType sType : nodesBySObjectType.keySet()) {
                List<Node> typeNodes = nodesBySObjectType.get(sType);
                List<SObject> records = new List<SObject>();
                
                for (Node node : typeNodes) {
                    node.wireLookups();
                    records.add(node.record);
                }
                
                insert records;
                inserted.addAll(typeNodes);
            }
        }
    }

    private Map<Schema.SObjectType, List<Node>> groupByType(List<Node> nodeList) {
        Map<Schema.SObjectType, List<Node>> result = new Map<Schema.SObjectType, List<Node>>();
        for (Node node : nodeList) {
            Schema.SObjectType sType = node.record.getSObjectType();
            if (!result.containsKey(sType)) {
                result.put(sType, new List<Node>());
            }
            result.get(sType).add(node);
        }
        return result;
    }

    /**
     * Internal node representing a registered record and its dependencies.
     */
    private class Node {
        public SObject record;
        private List<Dependency> dependencies = new List<Dependency>();

        public Node(SObject record) {
            this.record = record;
        }

        public void addDependency(Node parent, Schema.SObjectField lookupField) {
            dependencies.add(new Dependency(parent, lookupField));
        }

        public Boolean dependenciesSatisfied(Set<Node> inserted) {
            for (Dependency dep : dependencies) {
                if (!inserted.contains(dep.parentNode)) {
                    return false;
                }
            }
            return true;
        }

        public void wireLookups() {
            for (Dependency dep : dependencies) {
                record.put(dep.lookupField, dep.parentNode.record.Id);
            }
        }
    }

    /**
     * Represents a lookup dependency between child and parent.
     */
    private class Dependency {
        public Node parentNode;
        public Schema.SObjectField lookupField;

        public Dependency(Node parentNode, Schema.SObjectField lookupField) {
            this.parentNode = parentNode;
            this.lookupField = lookupField;
        }
    }

    public class TestDataGraphException extends Exception {}
}
